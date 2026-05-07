module Api
  module V1
    class LookupController < ApplicationController
      skip_before_action :authenticate_user!
      skip_before_action :set_tenant

      # GET /api/v1/lookup?email=...
      # Retorna todas las organizaciones a las que pertenece el email.
      # Si el email existe en una sola org → `organizations` tiene un elemento.
      # Si existe en varias → el frontend muestra un selector de org.
      def organization
        email = params[:email].to_s.strip.downcase

        unless email.present?
          render json: { error: "Email requerido" }, status: :bad_request
          return
        end

        users = ActsAsTenant.without_tenant { User.includes(:organization).where(email: email) }

        if users.empty?
          render json: { error: "No encontramos una cuenta con ese correo" }, status: :not_found
          return
        end

        organizations = users.map do |u|
          org      = u.organization
          logo_url = org.logo_file.attached? \
                       ? rails_blob_url(org.logo_file, host: request.base_url) \
                       : org.logo

          {
            slug:        org.slug,
            name:        org.name,
            logo_url:    logo_url,
            clinic_type: org.clinic_type,
            plan:        org.plan
          }
        end

        render json: { organizations: organizations }
      end
    end
  end
end
