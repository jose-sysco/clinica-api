module Api
  module V1
    module Auth
      class SessionsController < ApplicationController
        skip_before_action :authenticate_user!
        skip_before_action :set_tenant

        def create
          organization = Organization.find_by(slug: request.headers["X-Organization-Slug"], status: :active)

          if organization.nil?
            render json: { error: "Organización no encontrada" }, status: :not_found
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
              }
            }, status: :ok
          else
            render json: { error: "Email o contraseña incorrectos" }, status: :unauthorized
          end
        end

        def destroy
          token = request.headers["Authorization"]&.split(" ")&.last
          if token
            decoded = JWT.decode(
              token,
              Rails.application.credentials.devise_jwt_secret_key,
              true,
              algorithm: "HS256"
            ) rescue nil

            if decoded
              jti = decoded.first["jti"]
              exp = decoded.first["exp"]
              JwtDenylist.create(jti: jti, exp: Time.at(exp))
            end
          end
          render json: { message: "Sesión cerrada correctamente" }, status: :ok
        end

        private

        def generate_jwt(user)
          jti = SecureRandom.uuid
          payload = {
            sub:  user.id.to_s,
            jti:  jti,
            exp:  24.hours.from_now.to_i,
            org:  user.organization_id
          }
          JWT.encode(payload, Rails.application.credentials.devise_jwt_secret_key, "HS256")
        end
      end
    end
  end
end