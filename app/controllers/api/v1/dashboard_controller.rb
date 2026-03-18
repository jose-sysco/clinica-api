module Api
  module V1
    class DashboardController < BaseController
      def stats
        today      = Date.today
        tz         = ActsAsTenant.current_tenant.timezone
        week_start = today.beginning_of_week(:sunday)
        week_end   = today.end_of_week(:sunday)
        last_week_start = week_start - 1.week
        last_week_end   = week_end   - 1.week

        # ── Citas hoy ──────────────────────────────────────────────────
        appts_today = Appointment.where(scheduled_at: today.beginning_of_day..today.end_of_day)
        today_total     = appts_today.where.not(status: [:cancelled, :no_show]).count
        today_pending   = appts_today.where(status: :pending).count
        today_confirmed = appts_today.where(status: :confirmed).count
        today_completed = appts_today.where(status: :completed).count

        # ── Tendencia semana actual vs anterior ─────────────────────────
        this_week_count = Appointment.where(scheduled_at: week_start.beginning_of_day..week_end.end_of_day)
                                     .where.not(status: [:cancelled, :no_show]).count
        last_week_count = Appointment.where(scheduled_at: last_week_start.beginning_of_day..last_week_end.end_of_day)
                                     .where.not(status: [:cancelled, :no_show]).count
        week_change = last_week_count > 0 ? (((this_week_count - last_week_count).to_f / last_week_count) * 100).round(1) : nil

        # ── Nuevos pacientes esta semana vs anterior ────────────────────
        patients_this_week = Patient.where(created_at: week_start.beginning_of_day..week_end.end_of_day).count
        patients_last_week = Patient.where(created_at: last_week_start.beginning_of_day..last_week_end.end_of_day).count
        patients_change = patients_last_week > 0 ? (((patients_this_week - patients_last_week).to_f / patients_last_week) * 100).round(1) : nil

        # ── Tasa de asistencia (últimos 30 días) ────────────────────────
        last_30 = Appointment.where(scheduled_at: 30.days.ago..Time.current)
                             .where.not(status: [:cancelled, :no_show])
        total_30     = last_30.count
        completed_30 = last_30.where(status: :completed).count
        attendance_rate = total_30 > 0 ? ((completed_30.to_f / total_30) * 100).round(1) : nil

        # ── Próximas citas de hoy ───────────────────────────────────────
        upcoming = Appointment.includes(:patient, :doctor)
                              .where(scheduled_at: Time.current..today.end_of_day)
                              .where.not(status: [:cancelled, :no_show, :completed])
                              .order(:scheduled_at)
                              .limit(6)

        # ── Horas pico (semana actual) ──────────────────────────────────
        peak_hours = Appointment.where(scheduled_at: week_start.beginning_of_day..week_end.end_of_day)
                                .where.not(status: [:cancelled, :no_show])
                                .group("EXTRACT(HOUR FROM scheduled_at AT TIME ZONE 'UTC')")
                                .order("1 ASC")
                                .count
                                .map { |hour, count| { hour: "#{hour.to_i}:00", count: count } }

        render json: {
          # Stat cards principales
          appointments_today:   today_total,
          today_pending:        today_pending,
          today_confirmed:      today_confirmed,
          today_completed:      today_completed,
          doctors_active:       Doctor.active.count,
          patients_total:       Patient.active.count,
          owners_total:         Owner.count,

          # Tendencias
          appointments_this_week: this_week_count,
          appointments_last_week: last_week_count,
          week_change:            week_change,
          patients_this_week:     patients_this_week,
          patients_last_week:     patients_last_week,
          patients_change:        patients_change,
          attendance_rate:        attendance_rate,

          # Próximas citas hoy
          upcoming_today: upcoming.map { |a|
            {
              id:           a.id,
              time:         a.scheduled_at.in_time_zone(tz).strftime("%H:%M"),
              patient_name: a.patient.name,
              doctor_name:  a.doctor.full_name,
              status:       a.status
            }
          },

          # Horas pico
          peak_hours: peak_hours
        }
      end
    end
  end
end
