module Api
  module V1
    class DoctorsController < BaseController
      before_action :set_doctor,        only: [:show, :update, :destroy, :availability, :weekly_appointments]
      before_action :check_doctor_limit, only: [:create]

      def index
        authorize Doctor, policy_class: DoctorPolicy
        scope = Doctor.active.includes(:user, :schedules)

        if params[:q].present?
          q = "%#{params[:q].downcase}%"
          scope = scope.joins(:user).where(
            "LOWER(doctors.specialty) LIKE ? OR LOWER(users.first_name) LIKE ? OR LOWER(users.last_name) LIKE ?",
            q, q, q
          )
        end

        pagy, doctors = pagy(scope, limit: params[:per_page] || 10)

        render json: {
          data:       doctors.map { |d| doctor_json(d) },
          pagination: pagy_metadata(pagy)
        }
      end

      def show
        authorize @doctor, policy_class: DoctorPolicy
        render json: doctor_json(@doctor)
      end

      def create
        authorize Doctor, policy_class: DoctorPolicy

        doctor = nil
        ActiveRecord::Base.transaction do
          # Crear usuario con rol doctor
          user = User.new(user_params_for_doctor)
          user.organization = ActsAsTenant.current_tenant
          user.role         = :doctor
          user.status       = :active
          user.save!

          # Crear doctor asociado al usuario
          doctor = Doctor.new(doctor_params)
          doctor.user         = user
          doctor.organization = ActsAsTenant.current_tenant
          doctor.save!

          # Crear horarios si se enviaron
          Array(params[:schedules]).each do |s|
            doctor.schedules.create!(
              day_of_week: s[:day_of_week],
              start_time:  s[:start_time],
              end_time:    s[:end_time],
              is_active:   true
            )
          end
        end

        render json: doctor_json(doctor), status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      def update
        authorize @doctor, policy_class: DoctorPolicy
        @doctor.update!(doctor_params)
        render json: doctor_json(@doctor)
      end

      def destroy
        authorize @doctor, policy_class: DoctorPolicy
        @doctor.update!(status: :inactive)
        render json: { message: "Doctor desactivado correctamente" }
      end

      def availability
        date = params[:date]

        if date.blank?
          render json: { errors: "El parámetro date es requerido (YYYY-MM-DD)" }, status: :bad_request
          return
        end

        begin
          parsed_date = Date.parse(date)
        rescue ArgumentError
          render json: { error: "Formato de fecha inválido, usa YYYY-MM-DD" }, status: :bad_request
          return
        end

        if parsed_date < Date.today
          render json: { error: "No puedes consultar disponibilidad en fechas pasadas" }, status: :bad_request
          return
        end

        slots = DoctorAvailabilityService.new(@doctor, parsed_date).call

        render json: {
          doctor:          { id: @doctor.id, full_name: @doctor.full_name },
          date:            parsed_date,
          day:             parsed_date.strftime("%A"),
          slots:           slots.map { |s|
            {
              starts_at: s[:starts_at].in_time_zone(ActsAsTenant.current_tenant.timezone).strftime("%H:%M"),
              ends_at:   s[:ends_at].in_time_zone(ActsAsTenant.current_tenant.timezone).strftime("%H:%M")
            }
          },
          total_available: slots.count
        }
      end

      def weekly_appointments
        date         = params[:date] ? Date.parse(params[:date]) : Date.today
        start_of_week = date.beginning_of_week(:sunday)
        end_of_week   = date.end_of_week(:sunday)
        tz            = ActsAsTenant.current_tenant.timezone

        appointments = Appointment.includes(:patient, :owner)
                                  .where(doctor: @doctor.id)
                                  .where(scheduled_at: start_of_week.beginning_of_day..end_of_week.end_of_day)
                                  .where.not(status: [:cancelled, :no_show])
                                  .order(:scheduled_at)

        today_count = Appointment.where(doctor: @doctor.id)
                                 .where(scheduled_at: Date.today.beginning_of_day..Date.today.end_of_day)
                                 .where.not(status: [:cancelled, :no_show])
                                 .count

        render json: {
          doctor: {
            id:        @doctor.id,
            full_name: @doctor.full_name,
            specialty: @doctor.specialty,
            schedules: @doctor.schedules.map { |s| schedule_json(s) }
          },
          week_start:        start_of_week,
          week_end:          end_of_week,
          appointments_today: today_count,
          appointments: appointments.map { |a|
            {
              id:               a.id,
              patient_name:     a.patient.name,
              owner_name:       a.owner.full_name,
              scheduled_at:     a.scheduled_at.in_time_zone(tz).strftime("%Y-%m-%dT%H:%M:%S"),
              time:             a.scheduled_at.in_time_zone(tz).strftime("%H:%M"),
              date:             a.scheduled_at.in_time_zone(tz).strftime("%Y-%m-%d"),
              status:           a.status,
              reason:           a.reason,
              appointment_type: a.appointment_type
            }
          }
        }
      end

      private

      def set_doctor
        @doctor = Doctor.find(params[:id])
      end

      def check_doctor_limit
        config = PlanConfiguration.find_by(plan: ActsAsTenant.current_tenant.plan)
        return unless config&.max_doctors

        if Doctor.active.count >= config.max_doctors
          render json: {
            error: "Has alcanzado el límite de #{config.max_doctors} doctor(es) para tu plan #{config.display_name}. Actualiza tu plan para agregar más.",
            code:  "doctor_limit_reached"
          }, status: :forbidden
        end
      end

      def doctor_params
        params.require(:doctor).permit(
          :specialty, :license_number,
          :bio, :consultation_duration, :status
        )
      end

      def user_params_for_doctor
        params.require(:user).permit(
          :first_name, :last_name, :email, :phone,
          :password, :password_confirmation
        )
      end

      def doctor_json(doctor)
        tz          = ActsAsTenant.current_tenant.timezone
        today       = Date.today
        week_start  = today.beginning_of_week(:sunday)
        week_end    = today.end_of_week(:sunday)
        base_scope  = doctor.appointments.where.not(status: [:cancelled, :no_show])
        next_appt   = base_scope.where("scheduled_at > ?", Time.current)
                                .order(:scheduled_at)
                                .includes(:patient)
                                .first

        {
          id:                    doctor.id,
          full_name:             doctor.full_name,
          email:                 doctor.user.email,
          phone:                 doctor.user.phone,
          specialty:             doctor.specialty,
          license_number:        doctor.license_number,
          bio:                   doctor.bio,
          consultation_duration: doctor.consultation_duration,
          status:                doctor.status,
          schedules:             doctor.schedules.map { |s| schedule_json(s) },
          appointments_today:    base_scope.where(scheduled_at: today.beginning_of_day..today.end_of_day).count,
          appointments_this_week: base_scope.where(scheduled_at: week_start.beginning_of_day..week_end.end_of_day).count,
          next_appointment:      next_appt ? {
            scheduled_at: next_appt.scheduled_at.in_time_zone(tz).strftime("%Y-%m-%dT%H:%M:%S"),
            patient_name: next_appt.patient.name
          } : nil
        }
      end

      def schedule_json(schedule)
        {
          id:          schedule.id,
          day_of_week: schedule.day_of_week,
          start_time:  schedule.start_time.strftime("%H:%M"),
          end_time:    schedule.end_time.strftime("%H:%M"),
          is_active:   schedule.is_active
        }
      end
    end
  end
end
