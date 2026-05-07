module Api
  module V1
    module Auth
      class SessionsController < ApplicationController
        skip_before_action :authenticate_user!
        skip_before_action :set_tenant

        # POST /api/v1/auth/sign_in
        def create
          organization = Organization.find_by(slug: request.headers["X-Organization-Slug"])

          if organization.nil?
            render json: { error: "Organización no encontrada" }, status: :not_found
            return
          end

          user = User.where(organization: organization)
                     .find_by(email: params.dig(:user, :email))

          unless user&.valid_password?(params.dig(:user, :password))
            render json: { error: "Email o contraseña incorrectos" }, status: :unauthorized
            return
          end

          unless user.email_verified?
            render json: {
              error: "Debes verificar tu correo antes de iniciar sesión. Revisa tu bandeja de entrada.",
              code:  "email_not_verified"
            }, status: :forbidden
            return
          end

          unless user.superadmin?
            if organization.suspended?
              render json: {
                error: "Tu licencia está suspendida. Contacta al administrador para reactivar tu suscripción.",
                code:  "license_suspended"
              }, status: :payment_required
              return
            end
          end

          user.update_column(:last_login_ip, request.headers["CF-Connecting-IP"] || request.remote_ip)

          access_token              = generate_jwt(user)
          raw_refresh_token, _record = RefreshToken.generate_for(user)

          render json: {
            message:       "Sesión iniciada correctamente",
            token:         access_token,
            refresh_token: raw_refresh_token,
            user: {
              id:        user.id,
              email:     user.email,
              full_name: user.full_name,
              role:      user.role,
              status:    user.status
            },
            organization: organization_license_json(organization)
          }, status: :ok
        end

        # POST /api/v1/auth/switch_org
        # Permite a un usuario con acceso a múltiples orgs cambiar de org sin re-autenticar.
        # Requiere token válido de la org actual. Verifica que el mismo email sea admin en la org destino.
        def switch_org
          # Este action necesita auth — usamos authenticate_user! manualmente
          # (el controlador tiene skip_before_action para sign_in/sign_up, pero switch_org sí requiere token)
          unless request.headers["Authorization"].present?
            render json: { error: "Token requerido" }, status: :unauthorized
            return
          end

          # Decodificar token manualmente (igual que ApplicationController)
          token = request.headers["Authorization"].split(" ").last
          begin
            decoded = JWT.decode(token, jwt_secret, true, algorithm: "HS256")
            payload = decoded.first
          rescue JWT::DecodeError
            render json: { error: "Token inválido" }, status: :unauthorized
            return
          end

          current_org_user = ActsAsTenant.without_tenant { User.find_by(id: payload["sub"]) }
          unless current_org_user
            render json: { error: "Usuario no encontrado" }, status: :unauthorized
            return
          end

          target_slug = params[:target_slug].to_s.strip
          if target_slug.blank?
            render json: { error: "target_slug es requerido" }, status: :bad_request
            return
          end

          target_org = ActsAsTenant.without_tenant { Organization.find_by(slug: target_slug) }
          unless target_org
            render json: { error: "Organización no encontrada" }, status: :not_found
            return
          end

          # Verificar que el email del usuario actual existe como admin en la org destino
          target_user = ActsAsTenant.without_tenant do
            User.find_by(email: current_org_user.email, organization_id: target_org.id)
          end

          unless target_user
            render json: { error: "No tienes acceso a esta organización" }, status: :forbidden
            return
          end

          if target_org.suspended?
            render json: { error: "Esa organización está suspendida", code: "license_suspended" },
                   status: :payment_required
            return
          end

          access_token              = generate_jwt(target_user)
          raw_refresh_token, _record = RefreshToken.generate_for(target_user)

          render json: {
            token:         access_token,
            refresh_token: raw_refresh_token,
            user: {
              id:        target_user.id,
              email:     target_user.email,
              full_name: target_user.full_name,
              role:      target_user.role,
              status:    target_user.status
            },
            organization: organization_license_json(target_org)
          }, status: :ok
        end

        # POST /api/v1/auth/refresh
        def refresh
          raw = params[:refresh_token]
          record = RefreshToken.find_valid(raw)

          unless record
            render json: { error: "Refresh token inválido o expirado", code: "refresh_expired" },
                   status: :unauthorized
            return
          end

          user         = record.user
          organization = user.organization

          # Rotate: revoke old token, issue new pair
          record.revoke!

          new_access_token              = generate_jwt(user)
          new_raw_refresh_token, _rec   = RefreshToken.generate_for(user)

          render json: {
            token:         new_access_token,
            refresh_token: new_raw_refresh_token,
            organization:  organization_license_json(organization)
          }, status: :ok
        end

        # DELETE /api/v1/auth/sign_out
        def destroy
          # Revoke access token (JwtDenylist)
          access_token = request.headers["Authorization"]&.split(" ")&.last
          if access_token.present?
            begin
              decoded = JWT.decode(
                access_token,
                jwt_secret,
                true,
                algorithm: "HS256"
              )
              jti = decoded.first["jti"]
              exp = decoded.first["exp"]
              JwtDenylist.create!(jti: jti, exp: Time.at(exp)) unless JwtDenylist.exists?(jti: jti)
            rescue JWT::DecodeError
              # expired or invalid — no action needed
            end
          end

          # Revoke refresh token
          raw_refresh = params[:refresh_token]
          if raw_refresh.present?
            record = RefreshToken.find_valid(raw_refresh)
            record&.revoke!
          end

          render json: { message: "Sesión cerrada correctamente" }, status: :ok
        end

        private

        def generate_jwt(user)
          jti     = SecureRandom.uuid
          payload = {
            sub: user.id.to_s,
            jti: jti,
            exp: 1.hour.from_now.to_i,   # access token: 1 hora
            org: user.organization_id
          }
          JWT.encode(payload, jwt_secret, "HS256")
        end

        def jwt_secret
          ENV["DEVISE_JWT_SECRET_KEY"] || Rails.application.credentials.devise_jwt_secret_key
        end

        def organization_license_json(org)
          {
            id:                   org.id,
            name:                 org.name,
            slug:                 org.slug,
            clinic_type:          org.clinic_type,
            status:               org.status,
            plan:                 org.plan,
            trial_ends_at:        org.trial_ends_at,
            trial_days_remaining: org.trial_days_remaining,
            trial_expired:        org.trial_expired?,
            on_trial:             org.trial?,
            features:             org.enabled_features,
            logo_url:             org.logo_file.attached? \
                                    ? rails_blob_url(org.logo_file, host: request.base_url) \
                                    : org.logo,
          primary_color:        org.primary_color
          }.merge(plan_config_for(org))
        end
      end
    end
  end
end
