module Api
  module V1
    class OrganizationsController < BaseController
      skip_before_action :authenticate_user!, only: [:create]
      skip_before_action :set_tenant,         only: [:create]

      def show
        render json: organization_json(ActsAsTenant.current_tenant)
      end

      def create
        organization = Organization.new(organization_params)
        organization.save!
        render json: organization_json(organization), status: :created
      end

      def update
        ActsAsTenant.current_tenant.update!(organization_params)
        render json: organization_json(ActsAsTenant.current_tenant)
      end

      private

      def organization_params
        params.require(:organization).permit(
          :name, :slug, :subdomain, :email,
          :phone, :address, :city, :country,
          :timezone, :logo, :clinic_type
        )
      end

      def organization_json(org)
        {
          id:           org.id,
          name:         org.name,
          slug:         org.slug,
          subdomain:    org.subdomain,
          email:        org.email,
          phone:        org.phone,
          address:      org.address,
          city:         org.city,
          country:      org.country,
          timezone:     org.timezone,
          clinic_type:  org.clinic_type,
          status:       org.status
        }
      end
    end
  end
end