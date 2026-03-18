module Api
  module Superadmin
    class DashboardController < BaseController
      def stats
        ActsAsTenant.without_tenant do
          now  = Time.current
          orgs = Organization.all

          expiring_soon = orgs.trial
            .where('trial_ends_at >= ? AND trial_ends_at <= ?', now, 7.days.from_now)
            .order(:trial_ends_at)
            .map { |o| { id: o.id, name: o.name, email: o.email, trial_days_remaining: o.trial_days_remaining, trial_ends_at: o.trial_ends_at } }

          render json: {
            organizations: {
              total:               orgs.count,
              active_subscription: orgs.where.not(plan: :trial).where(status: :active).count,
              on_trial:            orgs.trial.where('trial_ends_at >= ?', now).count,
              trial_expired:       orgs.trial.where('trial_ends_at < ?', now).where.not(status: :suspended).count,
              suspended:           orgs.where(status: :suspended).count,
              expiring_soon:       expiring_soon.size,
              new_this_month:      orgs.where('created_at >= ?', now.beginning_of_month).count,
              new_last_month:      orgs.where(created_at: now.last_month.beginning_of_month..now.last_month.end_of_month).count
            },
            expiring_soon: expiring_soon,
            users: {
              total:       User.where.not(role: :superadmin).count,
              superadmins: User.where(role: :superadmin).count
            },
            appointments: {
              total:      Appointment.count,
              this_month: Appointment.where('created_at >= ?', now.beginning_of_month).count,
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
