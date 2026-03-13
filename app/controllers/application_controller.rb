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

      if JwtDenylist.exists?(jti: jti)
        render json: { error: "Token revocado" }, status: :unauthorized
        return
      end

      @current_user = User.find(user_id)
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
end