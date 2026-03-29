module Api
  module V1
    class ReportsController < BaseController
      def index
        unless ActsAsTenant.current_tenant.enabled_features.include?("reports")
          render json: { error: "Los reportes no están disponibles en tu plan actual." }, status: :forbidden
          return
        end

        parse_period
        render json: {
          period:                 { start: @start_date, end: @end_date },
          prev_period:            { start: @prev_start, end: @prev_end },
          summary:                summary_stats,
          funnel:                 funnel_stats,
          by_day_of_week:         by_day_of_week,
          by_type:                by_appointment_type,
          appointments_by_period: appointments_by_period,
          busiest_doctors:        busiest_doctors
        }
      end

      private

      # ── Período ────────────────────────────────────────────────────────────

      def parse_period
        if params[:start_date].present? && params[:end_date].present?
          @start_date = params[:start_date].to_date
          @end_date   = params[:end_date].to_date
        else
          now         = Time.current
          @start_date = now.beginning_of_month.to_date
          @end_date   = now.to_date
        end

        duration    = (@end_date - @start_date).to_i + 1
        @prev_start = @start_date - duration.days
        @prev_end   = @start_date - 1.day
      end

      def period_scope
        Appointment.by_range(@start_date, @end_date)
      end

      def prev_scope
        Appointment.by_range(@prev_start, @prev_end)
      end

      # ── Resumen con comparativa ────────────────────────────────────────────

      def summary_stats
        curr = status_counts(period_scope)
        prev = status_counts(prev_scope)

        total_curr = curr.values.sum
        total_prev = prev.values.sum

        {
          total:                  total_curr,
          completed:              curr[:completed].to_i,
          cancelled:              curr[:cancelled].to_i,
          no_show:                curr[:no_show].to_i,
          pending:                curr[:pending].to_i,
          confirmed:              curr[:confirmed].to_i,
          in_progress:            curr[:in_progress].to_i,
          completion_rate:        pct(curr[:completed], total_curr),
          cancellation_rate:      pct(curr[:cancelled], total_curr),
          no_show_rate:           pct(curr[:no_show], total_curr),
          # Período anterior
          prev_total:             total_prev,
          prev_completed:         prev[:completed].to_i,
          prev_completion_rate:   pct(prev[:completed], total_prev),
          prev_cancellation_rate: pct(prev[:cancelled], total_prev)
        }
      end

      def status_counts(scope)
        scope.group(:status).count.transform_keys(&:to_sym)
      end

      def pct(part, total)
        return 0.0 if total.to_i.zero?
        ((part.to_f / total) * 100).round(1)
      end

      # ── Funnel de conversión ───────────────────────────────────────────────

      def funnel_stats
        total     = period_scope.count
        confirmed = period_scope.where(status: %i[confirmed in_progress completed no_show]).count
        completed = period_scope.where(status: :completed).count

        [
          { stage: "Agendadas",   count: total,     pct: 100.0 },
          { stage: "Confirmadas", count: confirmed, pct: pct(confirmed, total) },
          { stage: "Completadas", count: completed, pct: pct(completed, total) }
        ]
      end

      # ── Citas por día de semana ────────────────────────────────────────────

      def by_day_of_week
        days = %w[Dom Lun Mar Mié Jue Vie Sáb]
        counts = period_scope
          .group(Arel.sql("EXTRACT(DOW FROM scheduled_at AT TIME ZONE 'UTC')::integer"))
          .count
        (0..6).map { |i| { day: days[i], count: counts[i].to_i } }
      end

      # ── Citas por tipo ─────────────────────────────────────────────────────

      def by_appointment_type
        period_scope
          .group(:appointment_type)
          .count
          .map { |type, count| { type: type, count: count } }
          .sort_by { |r| -r[:count] }
      end

      # ── Tendencia por período (día / semana / mes según rango) ─────────────

      def appointments_by_period
        duration = (@end_date - @start_date).to_i + 1

        if duration <= 31
          period_scope
            .group(Arel.sql("TO_CHAR(scheduled_at AT TIME ZONE 'UTC', 'YYYY-MM-DD')"))
            .order(Arel.sql("1 ASC"))
            .count
            .map { |d, c| { label: d, total: c } }
        elsif duration <= 92
          period_scope
            .group(Arel.sql("DATE_TRUNC('week', scheduled_at AT TIME ZONE 'UTC')"))
            .order(Arel.sql("1 ASC"))
            .count
            .map { |d, c| { label: d.to_date.strftime("%d %b"), total: c } }
        else
          period_scope
            .group(Arel.sql("TO_CHAR(scheduled_at AT TIME ZONE 'UTC', 'YYYY-MM')"))
            .order(Arel.sql("1 ASC"))
            .count
            .map { |m, c| { label: m, total: c } }
        end
      end

      # ── Doctores más activos con tasa de completadas ───────────────────────

      def busiest_doctors
        period_scope
          .joins(doctor: :user)
          .group(Arel.sql("doctors.id, users.first_name, users.last_name"))
          .order(Arel.sql("COUNT(*) DESC"))
          .limit(8)
          .pluck(
            "doctors.id",
            "users.first_name",
            "users.last_name",
            Arel.sql("COUNT(*)"),
            Arel.sql("SUM(CASE WHEN appointments.status = 3 THEN 1 ELSE 0 END)")
          )
          .map do |(doctor_id, first, last, total, completed)|
            total_i     = total.to_i
            completed_i = completed.to_i
            {
              doctor_id:       doctor_id,
              name:            "#{first} #{last}",
              total:           total_i,
              completed:       completed_i,
              completion_rate: pct(completed_i, total_i)
            }
          end
      end
    end
  end
end
