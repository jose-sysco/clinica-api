module Api
  module V1
    class DashboardController < BaseController
      def stats
        today = Date.today

        render json: {
          appointments_today: Appointment.where(
            scheduled_at: today.beginning_of_day..today.end_of_day
          ).where.not(status: [:cancelled, :no_show]).count,

          doctors_active: Doctor.active.count,
          patients_total: Patient.active.count,
          owners_total:   Owner.count
        }
      end
    end
  end
end