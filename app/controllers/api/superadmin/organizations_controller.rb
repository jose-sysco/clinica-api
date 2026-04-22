module Api
  module Superadmin
    class OrganizationsController < BaseController
      def index
        ActsAsTenant.without_tenant do
          orgs = Organization.order(created_at: :desc)
          orgs = orgs.where(status: params[:status]) if params[:status].present?
          orgs = orgs.where(plan: params[:plan])     if params[:plan].present?

          if params[:q].present?
            q = "%#{params[:q].downcase}%"
            orgs = orgs.where("LOWER(name) LIKE ? OR LOWER(email) LIKE ? OR slug LIKE ?", q, q, q)
          end

          pagy, orgs = pagy(orgs, limit: 15)

          render json: {
            data:       orgs.map { |o| org_summary_json(o) },
            pagination: pagy_metadata(pagy)
          }
        end
      end

      def show
        ActsAsTenant.without_tenant do
          org = Organization.find(params[:id])
          render json: org_detail_json(org)
        end
      end

      def update_license
        ActsAsTenant.without_tenant do
          org = Organization.find(params[:id])

          # Snapshot of fields before the update for the audit log
          tracked_fields = %i[plan status trial_ends_at suspended_at locked_price_monthly locked_price_monthly_usd]
          before_snapshot = tracked_fields.index_with { |f| org.public_send(f)&.to_s }

          updates = {}
          updates[:plan]          = params[:plan]          if params[:plan].present?
          updates[:status]        = params[:status]        if params[:status].present?
          updates[:trial_ends_at] = params[:trial_ends_at] if params[:trial_ends_at].present?

          if params[:status] == "suspended"
            updates[:suspended_at] = Time.current
          elsif params[:status] == "active"
            updates[:suspended_at] = nil
          end

          # Precio personalizado explícito (descuento, acuerdo especial)
          if params[:locked_price_monthly].present?
            updates[:locked_price_monthly] = params[:locked_price_monthly]
          end
          if params[:locked_price_monthly_usd].present?
            updates[:locked_price_monthly_usd] = params[:locked_price_monthly_usd]
          end

          # Si cambia de plan y no se especificó precio personalizado,
          # actualizar locked_price al precio vigente del nuevo plan.
          if params[:plan].present? && params[:locked_price_monthly].blank?
            plan_config = PlanConfiguration.find_by(plan: params[:plan])
            if plan_config
              updates[:locked_price_monthly]     = plan_config.price_monthly
              updates[:locked_price_monthly_usd] = plan_config.price_monthly_usd
            end
          end

          org.update!(updates)

          # Build diff for audit log
          after_snapshot = tracked_fields.index_with { |f| org.public_send(f)&.to_s }
          diff = tracked_fields.each_with_object({}) do |field, h|
            next if before_snapshot[field] == after_snapshot[field]

            h[field] = { from: before_snapshot[field], to: after_snapshot[field] }
          end

          LicenseChangeLog.create!(
            organization: org,
            changed_by:   current_user,
            changes:      diff,
            notes:        params[:notes].presence
          )

          render json: org_detail_json(org)
        end
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      def license_logs
        ActsAsTenant.without_tenant do
          org  = Organization.find(params[:id])
          logs = org.license_change_logs.order(created_at: :desc).limit(50)
          render json: logs.map { |l| license_log_json(l) }
        end
      end

      def billing_history
        ActsAsTenant.without_tenant do
          org     = Organization.find(params[:id])
          records = BillingRecord.where(organization: org).order(period: :desc)
          plan_configs = PlanConfiguration.all.index_by(&:plan)

          render json: records.map { |r|
            price_gtq = org.locked_price_monthly.presence&.to_f ||
                        plan_configs[org.plan]&.price_monthly.to_f
            billing_history_json(r, price_gtq)
          }
        end
      end

      private

      def org_summary_json(org)
        plan_config = PlanConfiguration.find_by(plan: org.plan)

        {
          id:                        org.id,
          name:                      org.name,
          slug:                      org.slug,
          email:                     org.email,
          phone:                     org.phone,
          city:                      org.city,
          country:                   org.country,
          clinic_type:               org.clinic_type,
          status:                    org.status,
          plan:                      org.plan,
          trial_ends_at:             org.trial_ends_at,
          trial_days_remaining:      org.trial_days_remaining,
          trial_expired:             org.trial_expired?,
          on_trial:                  org.trial?,
          expiring_soon:             org.expiring_soon?,
          suspended_at:              org.suspended_at,
          users_count:               org.users.count,
          doctors_count:             org.doctors.count,
          patients_count:            org.patients.count,
          appointments_count:        org.appointments.count,
          last_appointment_at:       org.appointments.maximum(:created_at),
          created_at:                org.created_at,
          registration_ip:           org.registration_ip,
          locked_price_monthly:      org.locked_price_monthly,
          locked_price_monthly_usd:  org.locked_price_monthly_usd,
          plan_price_monthly:        plan_config&.price_monthly,
          plan_price_monthly_usd:    plan_config&.price_monthly_usd,
          has_custom_price:          org.locked_price_monthly.present? &&
                                       org.locked_price_monthly != plan_config&.price_monthly
        }
      end

      def org_detail_json(org)
        org_summary_json(org).merge(
          phone:     org.phone,
          address:   org.address,
          city:      org.city,
          country:   org.country,
          timezone:  org.timezone,
          subdomain: org.subdomain,
          users:     org.users.order(:role, :first_name).map do |u|
            { id: u.id, full_name: u.full_name, email: u.email, role: u.role, status: u.status, last_login_ip: u.last_login_ip }
          end
        )
      end

      def license_log_json(log)
        {
          id:         log.id,
          changes:    log.changes,
          notes:      log.notes,
          changed_by: log.changed_by&.full_name || "Sistema",
          created_at: log.created_at
        }
      end

      def billing_history_json(record, price_gtq)
        {
          id:          record.id,
          period:      record.period.strftime("%Y-%m"),
          period_label: record.period.strftime("%B %Y"),
          amount_paid: record.amount_paid,
          currency:    record.currency,
          notes:       record.notes,
          recorded_at: record.recorded_at,
          recorded_by: record.recorded_by&.full_name,
          expected:    price_gtq,
          difference:  (record.amount_paid.to_f - price_gtq).round(2)
        }
      end
    end
  end
end
