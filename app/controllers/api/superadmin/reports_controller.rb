module Api
  module Superadmin
    class ReportsController < BaseController
      def commissions
        ActsAsTenant.without_tenant do
          month = params[:month].presence || Time.current.strftime("%Y-%m")
          year, mon = month.split("-").map(&:to_i)
          period_start = Date.new(year, mon, 1)

          plan_configs = PlanConfiguration.all.index_by { |c| c.plan.to_s }
          salespersons = Salesperson.order(:name).includes(:organizations)

          result = salespersons.map do |sp|
            active_orgs = sp.organizations
              .where(status: :active)
              .where.not(plan: :trial)
              .where.not(slug: "sistema-superadmin")
              .where("DATE(created_at) <= ?", period_start.end_of_month)

            orgs_data = active_orgs.map do |org|
              price      = org.locked_price_monthly.presence&.to_f ||
                           plan_configs[org.plan.to_s]&.price_monthly.to_f || 0.0
              commission = sp.commission_for_plan(org.plan)
              {
                id:               org.id,
                name:             org.name,
                plan:             org.plan,
                price_monthly:    price.round(2),
                commission:       commission,
                has_custom_price: org.locked_price_monthly.present?
              }
            end

            total_mrr        = orgs_data.sum { |o| o[:price_monthly] }.round(2)
            total_commission = orgs_data.sum { |o| o[:commission] }.round(2)

            {
              id:                  sp.id,
              name:                sp.name,
              email:               sp.email,
              phone:               sp.phone,
              commission_by_plan:  sp.commission_by_plan,
              active:              sp.active,
              organizations_count: orgs_data.size,
              attributed_mrr:      total_mrr,
              commission_amount:   total_commission,
              organizations:       orgs_data
            }
          end

          # Orgs sin vendedor asignado
          unassigned = Organization
            .where(salesperson_id: nil)
            .where(status: :active)
            .where.not(plan: :trial)
            .where.not(slug: "sistema-superadmin")
            .where("DATE(created_at) <= ?", period_start.end_of_month)
            .map do |org|
              price = org.locked_price_monthly.presence&.to_f ||
                      plan_configs[org.plan.to_s]&.price_monthly.to_f || 0.0
              { id: org.id, name: org.name, plan: org.plan, price_monthly: price.round(2), commission: 0 }
            end

          render json: {
            period:       month,
            salespersons: result,
            unassigned: {
              organizations_count: unassigned.size,
              mrr:                 unassigned.sum { |o| o[:price_monthly] }.round(2),
              organizations:       unassigned
            },
            totals: {
              organizations:    result.sum { |s| s[:organizations_count] } + unassigned.size,
              attributed_mrr:   result.sum { |s| s[:attributed_mrr] }.round(2),
              total_commission: result.sum { |s| s[:commission_amount] }.round(2)
            }
          }
        end
      end
    end
  end
end
