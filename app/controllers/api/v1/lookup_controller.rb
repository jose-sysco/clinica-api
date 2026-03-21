module Api
  module V1
    class LookupController < ApplicationController
      skip_before_action :authenticate_user!
      skip_before_action :set_tenant

      # GET /api/v1/lookup?email=...
      # Devuelve el slug y nombre de la organización a la que pertenece el email.
      # Endpoint público — no requiere token ni slug en headers.
      def organization
        email = params[:email].to_s.strip.downcase

        unless email.present?
          render json: { error: "Email requerido" }, status: :bad_request
          return
        end

        user = ActsAsTenant.without_tenant { User.find_by(email: email) }

        if user.nil?
          render json: { error: "No encontramos una cuenta con ese correo" }, status: :not_found
          return
        end

        org      = user.organization
        logo_url = org.logo_file.attached? \
                     ? rails_blob_url(org.logo_file, host: request.base_url) \
                     : org.logo

        render json: { slug: org.slug, name: org.name, logo_url: logo_url }
      end
    end
  end
end
