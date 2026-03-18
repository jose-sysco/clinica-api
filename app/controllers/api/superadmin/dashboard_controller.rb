module Api
  module Superadmin
    class DashboardController < BaseController
      def stats
        ActsAsTenant.without_tenant do
          now = Time.current
          orgs = Organization.all

          render json: {
            organizations: {
              total:               orgs.count,
              active_subscription: orgs.where.not(plan: :trial).where(status: :active).count,
              on_trial:            orgs.trial.where('trial_ends_at >= ?', now).count,
              trial_expired:       orgs.trial.where('trial_ends_at < ?', now).where.not(status: :suspended).count,
              suspended:           orgs.where(status: :suspended).count,
              new_this_month:      orgs.where('created_at >= ?', now.beginning_of_month).count
            },
            users: {
              total: User.count
            },
            appointments: {
              total:      Appointment.count,
              this_month: Appointment.where('created_at >= ?', now.beginning_of_month).count
            },
            by_clinic_type: orgs.group(:clinic_type).count,
            by_plan:        orgs.group(:plan).count
          }
        end
      end
    end
  end
end
