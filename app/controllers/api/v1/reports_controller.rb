module Api
  module V1
    class ReportsController < ApplicationController
      before_action :authenticate_user!

      def index
        render json: {
          appointments_by_month: appointments_by_month,
          busiest_doctors: busiest_doctors,
          cancellation_stats: cancellation_stats
        }
      end

      private

      def appointments_by_month
        Appointment
          .where("created_at >= ?", 12.months.ago)
          .group("TO_CHAR(created_at AT TIME ZONE 'UTC', 'YYYY-MM')")
          .order("1 ASC")
          .count
          .map { |month, count| { month: month, total: count } }
      end

      def busiest_doctors
        Appointment
          .joins(doctor: :user)
          .where(status: [:confirmed, :completed])
          .group("doctors.id", "users.first_name", "users.last_name")
          .order("count_all DESC")
          .limit(6)
          .count
          .map { |(id, first, last), count| { doctor_id: id, name: "#{first} #{last}", total: count } }
      end

      def cancellation_stats
        total     = Appointment.count
        cancelled = Appointment.where(status: :cancelled).count
        completed = Appointment.where(status: :completed).count
        confirmed = Appointment.where(status: :confirmed).count
        pending   = Appointment.where(status: :pending).count

        rate = total > 0 ? ((cancelled.to_f / total) * 100).round(1) : 0

        {
          total: total,
          cancelled: cancelled,
          completed: completed,
          confirmed: confirmed,
          pending: pending,
          cancellation_rate: rate
        }
      end
    end
  end
end