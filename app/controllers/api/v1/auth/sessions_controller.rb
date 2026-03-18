module Api
  module V1
    module Auth
      class SessionsController < ApplicationController
        skip_before_action :authenticate_user!
        skip_before_action :set_tenant

        def create
          organization = Organization.find_by(slug: request.headers["X-Organization-Slug"])

          if organization.nil?
            render json: { error: "Organización no encontrada" }, status: :not_found
            return
          end

          if organization.suspended?
            render json: {
              error: "Tu licencia está suspendida. Contacta al administrador para reactivar tu suscripción.",
              code: "license_suspended"
            }, status: :payment_required
            return
          end

          if organization.trial_expired?
            render json: {
              error: "Tu período de prueba ha expirado. Adquiere una suscripción para continuar.",
              code: "trial_expired"
            }, status: :payment_required
            return
          end

          user = User.where(organization: organization)
                     .find_by(email: params.dig(:user, :email))

          if user&.valid_password?(params.dig(:user, :password))
            token = generate_jwt(user)
            render json: {
              message: "Sesión iniciada correctamente",
              token: token,
              user: {
                id:        user.id,
                email:     user.email,
                full_name: user.full_name,
                role:      user.role,
                status:    user.status
              },
              organization: organization_license_json(organization)
            }, status: :ok
          else
            render json: { error: "Email o contraseña incorrectos" }, status: :unauthorized
          end
        end

        def destroy
          token = request.headers["Authorization"]&.split(" ")&.last

          if token.nil?
            render json: { message: "Sesión cerrada correctamente" }, status: :ok
            return
          end

          begin
            decoded = JWT.decode(
              token,
              Rails.application.credentials.devise_jwt_secret_key,
              true,
              algorithm: "HS256"
            )

            jti = decoded.first["jti"]
            exp = decoded.first["exp"]

            unless JwtDenylist.exists?(jti: jti)
              JwtDenylist.create!(jti: jti, exp: Time.at(exp))
            end

          rescue JWT::DecodeError
            # Token inválido o expirado, no importa — igual cerramos sesión
          end

          render json: { message: "Sesión cerrada correctamente" }, status: :ok
        end

        private

        def generate_jwt(user)
          jti = SecureRandom.uuid
          payload = {
            sub: user.id.to_s,
            jti: jti,
            exp: 24.hours.from_now.to_i,
            org: user.organization_id
          }
          JWT.encode(payload, ENV['DEVISE_JWT_SECRET_KEY'] || Rails.application.credentials.devise_jwt_secret_key, "HS256")
        end

        def organization_license_json(org)
          {
            id:                  org.id,
            name:                org.name,
            slug:                org.slug,
            clinic_type:         org.clinic_type,
            status:              org.status,
            plan:                org.plan,
            trial_ends_at:       org.trial_ends_at,
            trial_days_remaining: org.trial_days_remaining,
            trial_expired:       org.trial_expired?,
            on_trial:            org.trial?
          }
        end
      end
    end
  end
end
