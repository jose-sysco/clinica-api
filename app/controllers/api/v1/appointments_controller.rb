module Api
  module V1
    class AppointmentsController < BaseController
      before_action :set_appointment, only: [:show, :update, :cancel, :confirm]

      def index
        authorize Appointment, policy_class: AppointmentPolicy

        appointments = Appointment.includes(:doctor, :patient, :owner)

        appointments = appointments.for_doctor(params[:doctor_id])      if params[:doctor_id].present?
        appointments = appointments.for_patient(params[:patient_id])    if params[:patient_id].present?
        appointments = appointments.today                               if params[:today] == "true"
        appointments = appointments.upcoming                            if params[:upcoming] == "true"
        appointments = appointments.past                               if params[:past] == "true"
        appointments = appointments.by_status(params[:status])          if params[:status].present?
        appointments = appointments.by_type(params[:appointment_type])  if params[:appointment_type].present?
        appointments = appointments.by_date(params[:date])              if params[:date].present?

        if params[:from].present? && params[:to].present?
          appointments = appointments.by_range(params[:from], params[:to])
        end

        pagy, appointments = pagy(appointments, limit: params[:per_page] || 10)

        render json: {
          data:       appointments.map { |a| appointment_json(a) },
          pagination: pagy_metadata(pagy)
        }
      end

      def show
        authorize @appointment, policy_class: AppointmentPolicy
        render json: appointment_json(@appointment)
      end

      def create
        authorize Appointment, policy_class: AppointmentPolicy

        appointment = Appointment.new(appointment_params)
        appointment.save!

        # Programar recordatorio 24h antes
        reminder_time = appointment.scheduled_at - 24.hours
        if reminder_time > Time.current
          AppointmentReminderJob.set(wait_until: reminder_time).perform_later(appointment.id)
          Rails.logger.info "Recordatorio programado para #{reminder_time} — Cita ##{appointment.id}"
        end

        render json: appointment_json(appointment), status: :created
      end

      def update
        authorize @appointment, policy_class: AppointmentPolicy
        @appointment.update!(appointment_params)
        render json: appointment_json(@appointment)
      end

      def confirm
        authorize @appointment, policy_class: AppointmentPolicy

        if @appointment.confirmed?
          render json: { error: 'La cita ya está confirmada' }, status: :unprocessable_entity
          return
        end

        @appointment.confirmed!

        # Programar recordatorio 24h antes de la cita
        reminder_time = @appointment.scheduled_at - 24.hours
        if reminder_time > Time.current
          AppointmentReminderJob.set(wait_until: reminder_time).perform_later(@appointment.id)
          Rails.logger.info "Recordatorio programado para #{reminder_time} — Cita ##{@appointment.id}"
        end

        render json: { message: 'Cita confirmada correctamente' }, status: :ok
      end

      def cancel
        authorize @appointment, policy_class: AppointmentPolicy

        if @appointment.cancelled?
          render json: { error: "La cita ya está cancelada" }, status: :unprocessable_entity
          return
        end

        @appointment.update!(
          status:              :cancelled,
          cancelled_by:        params[:cancelled_by],
          cancellation_reason: params[:cancellation_reason]
        )
        render json: { message: "Cita cancelada correctamente" }
      end

      def complete
        authorize @appointment, policy_class: AppointmentPolicy

        if @appointment.complete?
          render json: { error: "La cita ya está completada" }, status: :unprocessable_entity
          return
        end

        @appointment.completed!
        render json: { message: "Cita completada correctamente" }, status: :ok
      end

      private

      def set_appointment
        @appointment = Appointment.find(params[:id])
      end

      def appointment_params
        params.require(:appointment).permit(
          :doctor_id, :patient_id, :owner_id,
          :scheduled_at, :ends_at, :appointment_type,
          :reason, :notes
        )
      end

      def appointment_json(appointment)
        {
          id:               appointment.id,
          scheduled_at:     appointment.scheduled_at.in_time_zone(appointment.organization.timezone).strftime("%Y-%m-%dT%H:%M:%S"),
          ends_at:          appointment.ends_at.in_time_zone(appointment.organization.timezone).strftime("%Y-%m-%dT%H:%M:%S"),
          status:           appointment.status,
          appointment_type: appointment.appointment_type,
          reason:           appointment.reason,
          notes:            appointment.notes,
          confirmed_at:     appointment.confirmed_at,
          doctor: {
            id:        appointment.doctor.id,
            full_name: appointment.doctor.full_name
          },
          patient: {
            id:   appointment.patient.id,
            name: appointment.patient.name
          },
          owner: {
            id:        appointment.owner.id,
            full_name: appointment.owner.full_name,
            phone:     appointment.owner.phone
          }
        }
      end
    end
  end
end