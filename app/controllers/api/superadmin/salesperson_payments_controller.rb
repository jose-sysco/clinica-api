module Api
  module Superadmin
    class SalespersonPaymentsController < BaseController
      before_action :load_salesperson

      # GET /api/superadmin/salespersons/:salesperson_id/payments
      def index
        payments = @salesperson.salesperson_payments.order(period: :desc)
        render json: payments.map { |p| payment_json(p) }
      end

      # GET /api/superadmin/salespersons/:salesperson_id/payments/preview?period=YYYY-MM
      def preview
        period = parse_period(params[:period] || Date.current.strftime("%Y-%m"))
        orgs   = active_orgs_for(@salesperson, period)
        total  = orgs.sum { |org| @salesperson.commission_for_plan(org.plan) }

        render json: {
          period:             period.strftime("%Y-%m"),
          period_label:       period.strftime("%B %Y").capitalize,
          calculated_amount:  total.round(2),
          orgs_count:         orgs.size,
          breakdown:          orgs.map { |org|
            {
              name:       org.name,
              plan:       org.plan,
              commission: @salesperson.commission_for_plan(org.plan)
            }
          }
        }
      end

      # POST /api/superadmin/salespersons/:salesperson_id/payments
      def create
        period = parse_period(params[:period])
        amount = if params[:amount].present?
                   params[:amount].to_f
                 else
                   active_orgs_for(@salesperson, period)
                     .sum { |org| @salesperson.commission_for_plan(org.plan) }
                     .round(2)
                 end

        payment = @salesperson.salesperson_payments.create!(
          period: period,
          amount: amount,
          notes:  params[:notes].presence
        )
        render json: payment_json(payment), status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      # PATCH /api/superadmin/salespersons/:salesperson_id/payments/:id
      def update
        payment = @salesperson.salesperson_payments.find(params[:id])

        if params[:paid].to_s == "true"
          payment.update!(paid_at: Time.current, paid_by: current_user,
                          notes: params[:notes].presence || payment.notes)
        elsif params[:paid].to_s == "false"
          payment.update!(paid_at: nil, paid_by: nil)
        else
          payment.update!(amount: params[:amount]) if params[:amount].present?
          payment.update!(notes: params[:notes])   if params.key?(:notes)
        end

        render json: payment_json(payment)
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      # DELETE /api/superadmin/salespersons/:salesperson_id/payments/:id
      def destroy
        @salesperson.salesperson_payments.find(params[:id]).destroy!
        head :no_content
      end

      private

      def load_salesperson
        ActsAsTenant.without_tenant do
          @salesperson = Salesperson.find(params[:salesperson_id])
        end
      end

      def parse_period(str)
        Date.strptime(str.to_s[0, 7], "%Y-%m").beginning_of_month
      rescue Date::Error
        Date.current.beginning_of_month
      end

      def active_orgs_for(sp, period)
        ActsAsTenant.without_tenant do
          Organization
            .where(salesperson: sp)
            .where(status: :active)
            .where.not(plan: :trial)
            .where("created_at <= ?", period.end_of_month)
            .to_a
        end
      end

      def payment_json(p)
        {
          id:           p.id,
          period:       p.period.strftime("%Y-%m"),
          period_label: p.period.strftime("%B %Y").capitalize,
          amount:       p.amount.to_f,
          paid:         p.paid?,
          paid_at:      p.paid_at,
          paid_by:      p.paid_by&.full_name,
          notes:        p.notes,
          created_at:   p.created_at
        }
      end
    end
  end
end
