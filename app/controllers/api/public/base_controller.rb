module Api
  module Public
    class BaseController < ActionController::API
      rescue_from StandardError do |e|
        Rails.logger.error "[Public API] #{e.class}: #{e.message}"
        render json: { error: "Error interno del servidor" }, status: :internal_server_error
      end

      private

      def bookable_org!(slug)
        org = ActsAsTenant.without_tenant { Organization.find_by!(slug: slug) }

        unless org.active? && !org.trial? && org.listed?
          render json: { error: "Clínica no disponible" }, status: :not_found
          return nil
        end

        org
      end
    end
  end
end
