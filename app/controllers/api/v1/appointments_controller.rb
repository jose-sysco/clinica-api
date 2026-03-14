module Api
  module V1
    class AppointmentsController < BaseController
      before_action :set_appointment, only: [:show, :update, :cancel, :confirm]

      def index
        appointments = Appointment.includes(:doctor, :patient, :owner)
        appointments = appointments.for_doctor(params[:doctor_id]) if params[:doctor_id].present?
        appointments = appointments.for_patient(params[:patient_id]) if params[:patient_id].present?
        appointments = appointments.today if params[:today].present?
        appointments = appointments.upcoming if params[:upcoming].present?
        render json: appointments.map { |a| appointment_json(a) }
      end

      def show
        render json: appointment_json(@appointment)
      end

      def create
        appointment = Appointment.new(appointment_params)
        appointment.save!
        render json: appointment_json(appointment), status: :created
      end

      def update
        @appointment.update!(appointment_params)
        render json: appointment_json(@appointment)
      end

      def confirm
        if !@appointment.cancelled?
          @appointment.confirmed!
          render json: { message: "Cita confirmada correctamente" }, status: :ok
        else
          render json: { error: "Cita cancelada" }, status: :unprocessable_entity
        end
      end

      def cancel
        @appointment.update!(
          status: :cancelled,
          cancelled_by: params[:cancelled_by],
          cancellation_reason: params[:cancellation_reason]
        )
        render json: { message: "Cita cancelada correctamente" }
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
          scheduled_at:     appointment.scheduled_at,
          ends_at:          appointment.ends_at,
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