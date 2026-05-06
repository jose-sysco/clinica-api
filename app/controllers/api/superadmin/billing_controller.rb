module Api
  module Superadmin
    class BillingController < BaseController
      # GET /api/superadmin/billing?period=2026-03&page=1
      def index
        period_str  = params[:period].presence || Date.current.strftime("%Y-%m")
        period_date = parse_period(period_str)

        ActsAsTenant.without_tenant do
          all_orgs = Organization
                       .where.not(slug: "sistema-superadmin")
                       .where.not(plan: :trial)
                       .where("created_at < ?", period_date.next_month)
                       .order(:name)

          all_records  = BillingRecord.where(period: period_date).index_by(&:organization_id)
          plan_configs = PlanConfiguration.all.index_by(&:plan)
          salespersons = Salesperson.all.index_by(&:id)

          # Totals + commissions computed on full set (not just current page)
          total_expected  = 0.0
          total_collected = 0.0
          commissions_map = {}

          all_orgs.each do |org|
            price_gtq = org.locked_price_monthly.presence&.to_f ||
                        plan_configs[org.plan]&.price_monthly.to_f
            total_expected  += price_gtq

            billing = all_records[org.id]
            if billing
              paid = billing.amount_paid.to_f
              total_collected += paid

              if org.salesperson_id && (sp = salespersons[org.salesperson_id])
                commission = sp.commission_for_plan(org.plan)
                commissions_map[sp.id] ||= { id: sp.id, name: sp.name, commission_by_plan: sp.commission_by_plan, commission_amount: 0.0, orgs_count: 0 }
                commissions_map[sp.id][:commission_amount] += commission
                commissions_map[sp.id][:orgs_count]        += 1
              end
            end
          end

          # Filter by payment status
          filtered_orgs = case params[:payment_status]
                          when "paid"   then all_orgs.where(id: all_records.keys)
                          when "unpaid" then all_orgs.where.not(id: all_records.keys)
                          else all_orgs
                          end

          pagy, paged_orgs = pagy(filtered_orgs, limit: 20)

          data = paged_orgs.map do |org|
            billing   = all_records[org.id]
            price_gtq = org.locked_price_monthly.presence&.to_f ||
                        plan_configs[org.plan]&.price_monthly.to_f
            price_usd = org.locked_price_monthly_usd.presence&.to_f ||
                        plan_configs[org.plan]&.price_monthly_usd.to_f

            {
              organization:   org_billing_json(org, price_gtq, price_usd),
              billing_record: billing ? billing_json(billing) : nil
            }
          end

          render json: {
            period:  period_str,
            summary: {
              total_orgs:          all_orgs.count,
              paid:                all_records.size,
              pending:             all_orgs.count - all_records.size,
              total_expected_gtq:  total_expected.round(2),
              total_collected_gtq: total_collected.round(2),
              collection_rate:     total_expected > 0 ? (total_collected / total_expected * 100).round(1) : 0,
              commissions:         commissions_map.values.map { |c| c.merge(commission_amount: c[:commission_amount].round(2)) },
              total_commissions:   commissions_map.values.sum { |c| c[:commission_amount] }.round(2)
            },
            pagination: pagy_metadata(pagy),
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

      def org_billing_json(org, price_gtq, price_usd)
        {
          id:               org.id,
          name:             org.name,
          slug:             org.slug,
          email:            org.email,
          phone:            org.phone,
          plan:             org.plan,
          status:           org.status,
          suspended_at:     org.suspended_at,
          doctors_count:    org.doctors.count,
          patients_count:   org.patients.count,
          price_gtq:        price_gtq,
          price_usd:        price_usd,
          has_custom_price: org.locked_price_monthly.present?,
          salesperson:      org.salesperson ? { id: org.salesperson.id, name: org.salesperson.name, commission_for_plan: org.salesperson.commission_for_plan(org.plan) } : nil
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
