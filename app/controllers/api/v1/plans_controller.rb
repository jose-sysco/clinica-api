module Api
  module V1
    class PlansController < BaseController
      # GET /api/v1/plans
      # Devuelve la configuración de todos los planes — disponible para cualquier
      # usuario autenticado.  Útil para que el frontend muestre la comparación de
      # planes sin depender de datos hardcodeados.
      def index
        ActsAsTenant.without_tenant do
          configs = PlanConfiguration.order(:plan)

          render json: {
            plans:    configs.map { |c| plan_json(c) },
            features: PlanConfiguration::FEATURES.map { |key, meta|
              { key: key, label: meta[:label], category: meta[:category] }
            }
          }
        end
      end

      private

      def plan_json(config)
        {
          key:               config.plan,
          display_name:      config.display_name || config.name,
          tagline:           tagline_for(config.plan),
          price_monthly:     config.price_monthly.to_f,
          price_monthly_usd: config.price_monthly_usd.to_f,
          max_doctors:       config.max_doctors,
          max_patients:      config.max_patients,
          features:          config.features || [],
        }
      end

      def tagline_for(plan)
        {
          "trial"        => "Para explorar la plataforma",
          "basic"        => "Ideal para consultorios pequeños",
          "professional" => "Para clínicas en crecimiento",
          "enterprise"   => "Para redes de clínicas y hospitales",
        }[plan] || ""
      end
    end
  end
end
