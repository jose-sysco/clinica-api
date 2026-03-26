module Api
  module V1
    class OrganizationsController < BaseController
      skip_before_action :authenticate_user!, only: [:create]
      skip_before_action :set_tenant,         only: [:create]

      def show
        authorize ActsAsTenant.current_tenant, policy_class: OrganizationPolicy
        render json: organization_json(ActsAsTenant.current_tenant)
      end

      def create
        organization = Organization.new(organization_params)
        organization.save!
        render json: organization_json(organization), status: :created
      end

      def update
        authorize ActsAsTenant.current_tenant, policy_class: OrganizationPolicy
        ActsAsTenant.current_tenant.update!(organization_params)
        render json: organization_json(ActsAsTenant.current_tenant)
      end

      # PATCH /api/v1/organization/upload_logo
      def upload_logo
        org = ActsAsTenant.current_tenant
        authorize org, policy_class: OrganizationPolicy

        file = params[:logo]

        unless file.present?
          render json: { error: "No se recibió ningún archivo" }, status: :unprocessable_entity
          return
        end

        unless file.content_type.start_with?("image/")
          render json: { error: "El archivo debe ser una imagen (PNG, JPG, SVG, WebP)" }, status: :unprocessable_entity
          return
        end

        if file.size > 2.megabytes
          render json: { error: "La imagen no puede superar los 2 MB" }, status: :unprocessable_entity
          return
        end

        org.logo_file.attach(file)

        render json: {
          logo_url: rails_blob_url(org.logo_file, host: request.base_url)
        }, status: :ok
      end

      private

      def organization_params
        params.require(:organization).permit(
          :name, :phone, :address, :city, :country,
          :timezone, :logo, :clinic_type
        )
      end

      def organization_json(org)
        {
          id:                   org.id,
          name:                 org.name,
          slug:                 org.slug,
          subdomain:            org.subdomain,
          email:                org.email,
          phone:                org.phone,
          address:              org.address,
          city:                 org.city,
          country:              org.country,
          timezone:             org.timezone,
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
        }.merge(plan_config_for(org))
      end
    end
  end
end
