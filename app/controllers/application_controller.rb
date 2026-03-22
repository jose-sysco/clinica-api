class ApplicationController < ActionController::API
  include ActsAsTenant::ControllerExtensions
  include Pundit::Authorization
  include Pagy::Backend

  before_action :authenticate_user!
  before_action :set_tenant

  rescue_from StandardError, with: :internal_server_error
  rescue_from Pundit::NotAuthorizedError, with: :forbidden

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
        ENV['DEVISE_JWT_SECRET_KEY'] || Rails.application.credentials.devise_jwt_secret_key,
        true,
        algorithm: "HS256"
      )

      jti     = decoded.first["jti"]
      user_id = decoded.first["sub"]
      org_id  = decoded.first["org"]

      if JwtDenylist.exists?(jti: jti)
        render json: { error: "Token revocado" }, status: :unauthorized
        return
      end

      organization = Organization.find_by(slug: request.headers["X-Organization-Slug"])

      if organization.nil? || organization.id != org_id
        render json: { error: "Token no válido para esta organización" }, status: :unauthorized
        return
      end

      @current_user = User.find_by(id: user_id, organization_id: org_id)

      if @current_user.nil?
        render json: { error: "Usuario no encontrado" }, status: :unauthorized
        return
      end

      # Superadmin nunca tiene restricciones de licencia
      return if @current_user.superadmin?

      if organization.suspended?
        render json: {
          error: "Licencia suspendida. Contacta al administrador para reactivar tu suscripción.",
          code: "license_suspended"
        }, status: :payment_required
        return
      end

      # Trial vencido: solo bloquea escrituras (POST, PATCH, PUT, DELETE)
      # Los GET siguen funcionando para que el usuario pueda ver sus datos
      if organization.trial_expired? && !request.get?
        render json: {
          error: "Tu período de prueba ha expirado. Solo puedes consultar información. Adquiere una suscripción para continuar.",
          code: "trial_expired"
        }, status: :payment_required
      end

    rescue JWT::DecodeError
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

    ActsAsTenant.current_tenant = organization
    # Set request-scoped timezone so all Time operations (slot generation,
    # comparisons, appointment display) use the org's configured timezone.
    # Falls back to the app default ('Central America') if not configured.
    Time.zone = organization.timezone.presence || Rails.application.config.time_zone
  end

  def find_organization
    slug = request.headers["X-Organization-Slug"]
    return nil if slug.blank?
    Organization.find_by(slug: slug)
  end

  def internal_server_error(error)
    Rails.logger.error error.message
    Rails.logger.error error.backtrace.join("\n")
    render json: { error: "Error interno del servidor" }, status: :internal_server_error
  end

  def forbidden
    render json: { error: "No tienes permisos para realizar esta acción" }, status: :forbidden
  end
end
