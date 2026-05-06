module Api
  module Superadmin
    class DashboardController < BaseController
      def stats
        ActsAsTenant.without_tenant do
          now  = Time.current
          orgs = Organization.all
          plan_configs = PlanConfiguration.all.index_by { |c| c.plan.to_s }

          expiring_soon = orgs.trial
            .where("trial_ends_at >= ? AND trial_ends_at <= ?", now, 7.days.from_now)
            .order(:trial_ends_at)
            .map { |o| { id: o.id, name: o.name, email: o.email, phone: o.phone, trial_days_remaining: o.trial_days_remaining, trial_ends_at: o.trial_ends_at } }

          suspended_orgs = orgs.where(status: :suspended)
            .order(Arel.sql("suspended_at DESC NULLS LAST"))
            .map { |o| { id: o.id, name: o.name, email: o.email, phone: o.phone, suspended_at: o.suspended_at } }

          # Clientes de pago sin registro en el mes actual
          period = now.beginning_of_month.to_date
          paying_orgs = Organization
            .where.not(slug: "sistema-superadmin")
            .where.not(plan: :trial)
            .where("created_at < ?", period.next_month)

          paid_org_ids = BillingRecord.where(period: period).pluck(:organization_id)
          unpaid_orgs  = paying_orgs.where.not(id: paid_org_ids).order(:name)
            .map { |o| { id: o.id, name: o.name, email: o.email, phone: o.phone, plan: o.plan } }

          # ── MRR ──────────────────────────────────────────────────────────────
          paying_active = Organization
            .where(status: :active)
            .where.not(plan: :trial)
            .where.not(slug: "sistema-superadmin")

          current_mrr = paying_active.sum do |org|
            org.locked_price_monthly.presence&.to_f ||
              plan_configs[org.plan.to_s]&.price_monthly.to_f || 0.0
          end.round(2)

          # MRR del mes anterior basado en billing records registrados
          last_month_period = now.last_month.beginning_of_month.to_date
          last_month_mrr = BillingRecord.where(period: last_month_period).sum(:amount_paid).to_f.round(2)

          mrr_by_plan = paying_active.group_by(&:plan).transform_values do |group|
            group.sum do |org|
              org.locked_price_monthly.presence&.to_f ||
                plan_configs[org.plan.to_s]&.price_monthly.to_f || 0.0
            end.round(2)
          end

          render json: {
            mrr: {
              current:     current_mrr,
              last_month:  last_month_mrr,
              by_plan:     mrr_by_plan,
              paying_orgs: paying_active.count
            },
            organizations: {
              total:               orgs.count,
              active_subscription: orgs.where.not(plan: :trial).where(status: :active).count,
              on_trial:            orgs.trial.where("trial_ends_at >= ?", now).count,
              trial_expired:       orgs.trial.where("trial_ends_at < ?", now).where.not(status: :suspended).count,
              suspended:           orgs.where(status: :suspended).count,
              expiring_soon:       expiring_soon.size,
              new_this_month:      orgs.where("created_at >= ?", now.beginning_of_month).count,
              new_last_month:      orgs.where(created_at: now.last_month.beginning_of_month..now.last_month.end_of_month).count
            },
            expiring_soon:  expiring_soon,
            suspended_orgs: suspended_orgs,
            unpaid_this_month: {
              count: unpaid_orgs.size,
              orgs:  unpaid_orgs
            },
            users: {
              total:       User.where.not(role: :superadmin).count,
              superadmins: User.where(role: :superadmin).count
            },
            appointments: {
              total:      Appointment.count,
              this_month: Appointment.where("created_at >= ?", now.beginning_of_month).count,
              last_month: Appointment.where(created_at: now.last_month.beginning_of_month..now.last_month.end_of_month).count
            },
            by_clinic_type: orgs.group(:clinic_type).count,
            by_plan:        orgs.group(:plan).count
          }
        end
      end
    end
  end
end
