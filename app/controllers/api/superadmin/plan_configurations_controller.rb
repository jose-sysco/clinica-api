module Api
  module Superadmin
    class PlanConfigurationsController < BaseController
      def index
        ActsAsTenant.without_tenant do
          configs = PlanConfiguration.order(:plan)
          render json: {
            plans:    configs.map { |c| config_json(c) },
            features: PlanConfiguration::FEATURES
          }
        end
      end

      def update
        ActsAsTenant.without_tenant do
          config = PlanConfiguration.find(params[:id])

          attrs = {}
          attrs[:features]      = Array(params[:features])      if params.key?(:features)
          attrs[:name]          = params[:name]                 if params[:name].present?
          attrs[:price_monthly] = params[:price_monthly]        if params.key?(:price_monthly)

          config.update!(attrs)
          render json: config_json(config)
        end
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      private

      def config_json(config)
        {
          id:            config.id,
          plan:          config.plan,
          name:          config.name,
          price_monthly: config.price_monthly.to_f,
          features:      config.features
        }
      end
    end
  end
end
