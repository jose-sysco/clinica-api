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

          unless user.superadmin?
            if organization.suspended?
              render json: {
                error: "Tu licencia está suspendida. Contacta al administrador para reactivar tu suscripción.",
                code:  "license_suspended"
              }, status: :payment_required
              return
            end
          end

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
                                    : org.logo
          }
        end
      end
    end
  end
end
