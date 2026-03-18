module Api
  module V1
    class DoctorsController < BaseController
      before_action :set_doctor, only: [:show, :update, :destroy, :availability, :weekly_appointments]

      def index
        authorize Doctor, policy_class: DoctorPolicy
        pagy, doctors = pagy(Doctor.active.includes(:user, :schedules), limit: params[:per_page] || 10)

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
        doctor = Doctor.new(doctor_params)
        doctor.save!
        render json: doctor_json(doctor), status: :created
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
          render json: {error: "No puedes consultar disponibilidad en fechas pasadas"}, status: :bad_request
          return 
        end

        slots = DoctorAvailabilityService.new(@doctor, parsed_date).call

        render json: {
          doctor:   { id: @doctor.id, full_name: @doctor.full_name },
          date:     parsed_date,
          day:      parsed_date.strftime("%A"),
          slots:    slots.map { |s|
            {
              starts_at: s[:starts_at].in_time_zone(ActsAsTenant.current_tenant.timezone).strftime("%H:%M"),
              ends_at:   s[:ends_at].in_time_zone(ActsAsTenant.current_tenant.timezone).strftime("%H:%M")
            }
          },
          total_available: slots.count
        }
      end

      def weekly_appointments
        date = params[:date] ? Date.parse(params[:date]) : Date.today
        start_of_week = date.beginning_of_week(:sunday)
        end_of_week = date.end_of_week(:sunday)

        appointments = Appointment.includes(:patient, :owner)
                                  .where(doctor: @doctor.id)
                                  .where(scheduled_at: start_of_week.beginning_of_day..end_of_week.end_of_day)
                                  .where.not(status: [:cancelled, :no_show])
                                  .order(:scheduled_at)

        render json: {
          doctor:     { id: @doctor.id, full_name: @doctor.full_name },
          week_start: start_of_week,
          week_end:   end_of_week,
          appointments: appointments.map { |a|
            {
              id:           a.id,
              patient_name: a.patient.name,
              owner_name:   a.owner.full_name,
              scheduled_at: a.scheduled_at.in_time_zone(ActsAsTenant.current_tenant.timezone).strftime("%Y-%m-%dT%H:%M:%S"),
              time:         a.scheduled_at.in_time_zone(ActsAsTenant.current_tenant.timezone).strftime("%H:%M"),
              date:         a.scheduled_at.in_time_zone(ActsAsTenant.current_tenant.timezone).strftime("%Y-%m-%d"),
              status:       a.status,
              reason:       a.reason,
              appointment_type: a.appointment_type
            }
          }
        }
      end

      private

      def set_doctor
        @doctor = Doctor.find(params[:id])
      end

      def doctor_params
        params.require(:doctor).permit(
          :user_id, :specialty, :license_number,
          :bio, :consultation_duration, :status
        )
      end

      def doctor_json(doctor)
        {
          id:                   doctor.id,
          full_name:            doctor.full_name,
          email:                doctor.user.email,
          phone:                doctor.user.phone,
          specialty:            doctor.specialty,
          license_number:       doctor.license_number,
          bio:                  doctor.bio,
          consultation_duration: doctor.consultation_duration,
          status:               doctor.status,
          schedules:            doctor.schedules.map { |s| schedule_json(s) }
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