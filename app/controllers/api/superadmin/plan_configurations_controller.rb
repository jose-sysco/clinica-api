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
          attrs[:features]           = Array(params[:features])      if params.key?(:features)
          attrs[:name]               = params[:name]               if params[:name].present?
          attrs[:display_name]       = params[:display_name]       if params.key?(:display_name)
          attrs[:price_monthly]      = params[:price_monthly]      if params.key?(:price_monthly)
          attrs[:price_monthly_usd]  = params[:price_monthly_usd]  if params.key?(:price_monthly_usd)
          attrs[:max_doctors]        = params[:max_doctors]        if params.key?(:max_doctors)
          attrs[:max_patients]       = params[:max_patients]       if params.key?(:max_patients)

          config.update!(attrs)
          render json: config_json(config)
        end
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      private

      def config_json(config)
        {
          id:                config.id,
          plan:              config.plan,
          name:              config.name,
          display_name:      config.display_name,
          price_monthly:     config.price_monthly.to_f,
          price_monthly_usd: config.price_monthly_usd.to_f,
          max_doctors:       config.max_doctors,
          max_patients:      config.max_patients,
          features:          config.features,
        }
      end
    end
  end
end
