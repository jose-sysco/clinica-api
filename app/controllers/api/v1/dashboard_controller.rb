module Api
  module V1
    class DashboardController < BaseController
      # ── stats ─────────────────────────────────────────────────────────────────
      # Disponible para todos los planes.
      # Doctores ven únicamente sus propias citas; admin/recepcionista ven todo.
      def stats
        today           = Date.today
        tz              = ActsAsTenant.current_tenant.timezone
        week_start      = today.beginning_of_week(:sunday)
        week_end        = today.end_of_week(:sunday)
        last_week_start = week_start - 1.week
        last_week_end   = week_end   - 1.week

        # Scope base según rol
        appt_scope = doctor_scoped_appointments

        # ── Citas hoy ─────────────────────────────────────────────────────────
        appts_today     = appt_scope.where(scheduled_at: today.beginning_of_day..today.end_of_day)
        today_total     = appts_today.where.not(status: [:cancelled, :no_show]).count
        today_pending   = appts_today.where(status: :pending).count
        today_confirmed = appts_today.where(status: :confirmed).count
        today_completed = appts_today.where(status: :completed).count

        # ── Tendencia semana actual vs anterior ───────────────────────────────
        this_week_count = appt_scope.where(scheduled_at: week_start.beginning_of_day..week_end.end_of_day)
                                    .where.not(status: [:cancelled, :no_show]).count
        last_week_count = appt_scope.where(scheduled_at: last_week_start.beginning_of_day..last_week_end.end_of_day)
                                    .where.not(status: [:cancelled, :no_show]).count
        week_change = last_week_count > 0 ? (((this_week_count - last_week_count).to_f / last_week_count) * 100).round(1) : nil

        # ── Nuevos pacientes esta semana vs anterior ──────────────────────────
        patients_this_week = Patient.where(created_at: week_start.beginning_of_day..week_end.end_of_day).count
        patients_last_week = Patient.where(created_at: last_week_start.beginning_of_day..last_week_end.end_of_day).count
        patients_change    = patients_last_week > 0 ? (((patients_this_week - patients_last_week).to_f / patients_last_week) * 100).round(1) : nil

        # ── Tasa de asistencia (últimos 30 días) ──────────────────────────────
        last_30      = appt_scope.where(scheduled_at: 30.days.ago..Time.current).where.not(status: [:cancelled, :no_show])
        total_30     = last_30.count
        completed_30 = last_30.where(status: :completed).count
        attendance_rate = total_30 > 0 ? ((completed_30.to_f / total_30) * 100).round(1) : nil

        # ── Próximas citas de hoy ─────────────────────────────────────────────
        upcoming = appt_scope.includes(:patient, :doctor)
                             .where(scheduled_at: Time.current..today.end_of_day)
                             .where.not(status: [:cancelled, :no_show, :completed])
                             .order(:scheduled_at)
                             .limit(6)

        # ── Horas pico semana actual (en timezone de la org) ──────────────────
        peak_hours = appt_scope
          .where(scheduled_at: week_start.beginning_of_day..week_end.end_of_day)
          .where.not(status: [:cancelled, :no_show])
          .group(Arel.sql("EXTRACT(HOUR FROM scheduled_at AT TIME ZONE '#{tz}')::integer"))
          .order(Arel.sql("1 ASC"))
          .count
          .map { |hour, count| { hour: "#{hour.to_i}:00", count: count } }

        render json: {
          appointments_today:      today_total,
          today_pending:           today_pending,
          today_confirmed:         today_confirmed,
          today_completed:         today_completed,
          doctors_active:          Doctor.active.count,
          patients_total:          Patient.active.count,
          owners_total:            Owner.count,

          appointments_this_week:  this_week_count,
          appointments_last_week:  last_week_count,
          week_change:             week_change,
          patients_this_week:      patients_this_week,
          patients_last_week:      patients_last_week,
          patients_change:         patients_change,
          attendance_rate:         attendance_rate,

          upcoming_today: upcoming.map { |a|
            {
              id:           a.id,
              time:         a.scheduled_at.in_time_zone(tz).strftime("%H:%M"),
              patient_name: a.patient.name,
              doctor_name:  a.doctor.full_name,
              status:       a.status
            }
          },

          peak_hours: peak_hours
        }
      end

      # ── charts ────────────────────────────────────────────────────────────────
      # Gráficas básicas del dashboard — disponibles para TODOS los planes.
      # Devuelve los campos exactos que espera el frontend:
      #   appointments_by_month  → array { month: "YYYY-MM", total: N }
      #   cancellation_stats     → { completed, confirmed, pending, cancelled }
      def charts
        tz = ActsAsTenant.current_tenant.timezone
        appt_scope = doctor_scoped_appointments

        appointments_by_month = appt_scope
          .where(scheduled_at: 12.months.ago..Time.current)
          .group(Arel.sql("TO_CHAR(scheduled_at AT TIME ZONE '#{tz}', 'YYYY-MM')"))
          .order(Arel.sql("1 ASC"))
          .count
          .map { |month, total| { month: month, total: total } }

        status_counts = appt_scope.group(:status).count.transform_keys(&:to_s)
        cancellation_stats = {
          completed: status_counts["completed"].to_i,
          confirmed: status_counts["confirmed"].to_i,
          pending:   status_counts["pending"].to_i,
          cancelled: status_counts["cancelled"].to_i,
        }

        render json: {
          appointments_by_month: appointments_by_month,
          cancellation_stats:    cancellation_stats,
        }
      end

      # ── alerts ────────────────────────────────────────────────────────────────
      # Alertas operacionales — disponibles para TODOS los planes.
      def alerts
        org    = ActsAsTenant.current_tenant
        result = []

        # Doctores activos sin ningún horario configurado
        doctors_no_schedule = Doctor.active
          .left_joins(:schedules)
          .where(schedules: { id: nil })
          .includes(:user)

        if doctors_no_schedule.any?
          result << {
            type:    "warning",
            key:     "doctors_without_schedule",
            title:   "Doctores sin horario",
            message: "#{doctors_no_schedule.count} doctor(es) no tienen horario configurado y no pueden recibir citas.",
            count:   doctors_no_schedule.count,
            data:    doctors_no_schedule.map { |d| { id: d.id, name: d.full_name } }
          }
        end

        # Citas pendientes de confirmar hoy
        pending_today = Appointment.today.where(status: :pending).count
        if pending_today > 0
          result << {
            type:    "info",
            key:     "pending_today",
            title:   "Citas sin confirmar hoy",
            message: "#{pending_today} cita(s) de hoy están pendientes de confirmación.",
            count:   pending_today,
            data:    []
          }
        end

        # Trial por vencer (≤ 3 días)
        if org.trial? && org.trial_days_remaining <= 3 && !org.trial_expired?
          result << {
            type:    "danger",
            key:     "trial_expiring",
            title:   "Período de prueba por vencer",
            message: "Tu período de prueba vence en #{org.trial_days_remaining} día(s). Activa tu suscripción para no perder el acceso.",
            count:   org.trial_days_remaining,
            data:    []
          }
        end

        render json: { alerts: result }
      end

      private

      # Scope base de citas según rol del usuario autenticado.
      # Doctores ven solo sus citas; admin y recepcionistas ven toda la org.
      def doctor_scoped_appointments
        if current_user.role == "doctor" && (doctor = current_user.doctor)
          Appointment.for_doctor(doctor.id)
        else
          Appointment.all
        end
      end
    end
  end
end
