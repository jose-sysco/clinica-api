module Api
  module Superadmin
    class BaseController < ActionController::API
      include Pagy::Backend

      before_action :authenticate_superadmin!

      rescue_from StandardError, with: :internal_server_error

      private

      def authenticate_superadmin!
        token = request.headers["Authorization"]&.split(" ")&.last

        if token.nil?
          render json: { error: "Token no proporcionado" }, status: :unauthorized
          return
        end

        begin
          decoded = JWT.decode(
            token,
            ENV["DEVISE_JWT_SECRET_KEY"] || Rails.application.credentials.devise_jwt_secret_key,
            true,
            algorithm: "HS256"
          )

          jti     = decoded.first["jti"]
          user_id = decoded.first["sub"]

          if JwtDenylist.exists?(jti: jti)
            render json: { error: "Token revocado" }, status: :unauthorized
            return
          end

          ActsAsTenant.without_tenant do
            @current_user = User.find_by(id: user_id)
          end

          unless @current_user&.superadmin?
            render json: { error: "Acceso denegado. Se requiere rol superadmin." }, status: :forbidden
          end

        rescue JWT::DecodeError
          render json: { error: "Token inválido" }, status: :unauthorized
        end
      end

      def current_user
        @current_user
      end

      def internal_server_error(error)
        Rails.logger.error error.message
        Rails.logger.error error.backtrace.join("\n")
        render json: { error: "Error interno del servidor" }, status: :internal_server_error
      end
    end
  end
end
