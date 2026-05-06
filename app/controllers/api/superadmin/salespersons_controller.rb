module Api
  module Superadmin
    class SalespersonsController < BaseController
      def index
        salespersons = Salesperson.order(:name)
        render json: salespersons.map { |s| salesperson_json(s) }
      end

      def create
        sp = Salesperson.new(salesperson_params)
        sp.save!
        render json: salesperson_json(sp), status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      def update
        sp = Salesperson.find(params[:id])
        sp.update!(salesperson_params)
        render json: salesperson_json(sp)
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      def destroy
        sp = Salesperson.find(params[:id])
        sp.update!(active: false)
        render json: salesperson_json(sp)
      end

      private

      def salesperson_params
        base = params.permit(:name, :email, :phone, :active)
        if params[:commission_by_plan].present?
          base[:commission_by_plan] = params[:commission_by_plan]
            .to_unsafe_h
            .slice("basic", "professional", "enterprise")
            .transform_values { |v| v.to_f.round(2) }
        end
        base
      end

      def salesperson_json(sp)
        {
          id:                  sp.id,
          name:                sp.name,
          email:               sp.email,
          phone:               sp.phone,
          commission_by_plan:  sp.commission_by_plan,
          active:              sp.active,
          organizations_count: ActsAsTenant.without_tenant { sp.organizations.where(status: :active).where.not(plan: :trial).count },
          created_at:          sp.created_at
        }
      end
    end
  end
end
