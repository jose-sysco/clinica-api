class ApplicationController < ActionController::API
    include ActsAsTenant::ControllerExtensions

    before_action :authenticate_user!
    before_action :set_tenant

    private 

    def set_tenant
        organization = find_organization
        if organization.nil?
            render json: {error: "Organización no encontrada"}, status: :not_found
            return
        end

        if organization.suspended?
            render json: {error: "Organización suspendida"}, status: :forbidden
            return 
        end

        ActsAsTenant.current_tenant = organization
    end

    def find_organization
        # Buscar por header X-Organization-Slug: mi-clinica
        slug = request.headers["X-Organization-Slug"]
        return nil if slug.blank?

        Organization.find_by(slug: slug, status: :active)
    end
end
