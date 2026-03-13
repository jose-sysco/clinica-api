class ApplicationController < ActionController::API
  include ActsAsTenant::ControllerExtensions

  before_action :authenticate_user!
  before_action :set_tenant

  private

  def authenticate_user!
    token = request.headers["Authorization"]&.split(" ")&.last
    if token.nil?
      render json: { error: "Token no proporcionado" }, status: :unauthorized
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
      user_id = decoded.first["sub"]
      org_id = decoded.first["org"]

      if JwtDenylist.exists?(jti: jti)
        render json: { error: "Token revocado" }, status: :unauthorized
        return
      end

      # Verificar que el token pertenece realmente a la organizacion 
      organization = Organization.find_by(slug: request.headers["X-Organization-Slug"])

      if organization.nil? || organization.id != org_id
        render json: { error: "Token inválido para esta solicitud"}, status: :unauthorized
        return
      end

      @current_user = User.find_by(id: user_id, organization_id: org_id)

      if @current_user.nil?
        render json: { error: "Usuario no encontrado"}, status: unauthorized
        return
      end

    rescue JWT::DecodeError, ActiveRecord::RecordNotFound
      render json: { error: "Token inválido" }, status: :unauthorized
    end
  end

  def current_user
    @current_user
  end

  def set_tenant
    organization = find_organization
    if organization.nil?
      render json: { error: "Organización no encontrada" }, status: :not_found
      return
    end

    if organization.suspended?
      render json: { error: "Organización suspendida" }, status: :forbidden
      return
    end

    ActsAsTenant.current_tenant = organization
  end

  def find_organization
    slug = request.headers["X-Organization-Slug"]
    return nil if slug.blank?
    Organization.find_by(slug: slug, status: :active)
  end

  def not_found
    render json: { error: "Ruta no encontrada" }, status: :not_found
  end

  def internal_server_error(error)
    Rails.logger.error error.message
    Rails.logger.error error.backtrace.join("\n")
    render json: { error: "Error interno del servidor" }, status: :internal_server_error
  end
end