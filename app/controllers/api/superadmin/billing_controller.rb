module Api
  module Superadmin
    class BillingController < BaseController
      # GET /api/superadmin/billing?period=2026-03
      def index
        period_str  = params[:period].presence || Date.current.strftime("%Y-%m")
        period_date = parse_period(period_str)

        ActsAsTenant.without_tenant do
          orgs = Organization
                   .where.not(slug: "sistema-superadmin")
                   .where.not(plan: :trial)
                   .where("created_at < ?", period_date.next_month)
                   .order(:name)

          records      = BillingRecord.where(period: period_date).index_by(&:organization_id)
          plan_configs = PlanConfiguration.all.index_by(&:plan)

          total_expected  = 0.0
          total_collected = 0.0

          data = orgs.map do |org|
            billing    = records[org.id]
            price_gtq  = plan_configs[org.plan]&.price_monthly.to_f

            total_expected  += price_gtq
            total_collected += billing&.amount_paid.to_f

            {
              organization:  org_billing_json(org),
              plan_price_gtq: price_gtq,
              billing_record: billing ? billing_json(billing) : nil
            }
          end

          render json: {
            period:  period_str,
            summary: {
              total_orgs:          orgs.count,
              paid:                records.size,
              pending:             orgs.count - records.size,
              total_expected_gtq:  total_expected,
              total_collected_gtq: total_collected
            },
            data: data
          }
        end
      end

      # POST /api/superadmin/billing
      def create
        period_date = parse_period(params[:period])

        ActsAsTenant.without_tenant do
          org = Organization.find(params[:organization_id])

          record = BillingRecord.new(
            organization:  org,
            period:        period_date,
            amount_paid:   params[:amount_paid],
            currency:      params[:currency].presence || "GTQ",
            notes:         params[:notes],
            recorded_by:   current_user,
            recorded_at:   Time.current
          )

          if record.save
            render json: billing_json(record), status: :created
          else
            render json: { errors: record.errors.full_messages }, status: :unprocessable_entity
          end
        end
      end

      # DELETE /api/superadmin/billing/:id
      def destroy
        ActsAsTenant.without_tenant do
          record = BillingRecord.find(params[:id])
          record.destroy!
          render json: { message: "Pago eliminado correctamente" }
        end
      end

      private

      def parse_period(str)
        year, month = str.to_s.split("-").map(&:to_i)
        Date.new(year, month, 1)
      rescue ArgumentError
        Date.current.beginning_of_month
      end

      def org_billing_json(org)
        {
          id:             org.id,
          name:           org.name,
          slug:           org.slug,
          email:          org.email,
          plan:           org.plan,
          status:         org.status,
          suspended_at:   org.suspended_at,
          doctors_count:  org.doctors.count,
          patients_count: org.patients.count
        }
      end

      def billing_json(record)
        {
          id:          record.id,
          period:      record.period.strftime("%Y-%m"),
          amount_paid: record.amount_paid,
          currency:    record.currency,
          notes:       record.notes,
          recorded_at: record.recorded_at,
          recorded_by: record.recorded_by&.full_name
        }
      end
    end
  end
end
