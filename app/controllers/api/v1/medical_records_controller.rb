module Api
  module V1
    class MedicalRecordsController < BaseController
      before_action :set_patient, only: [:index]
      before_action :set_medical_record, only: [:show, :update]

      def index
        records = @patient.medical_records
                          .includes(:appointment, :doctor)
                          .order(created_at: :desc)

        render json: records.map { |r| medical_record_json(r) }
      end

      def show
        render json: medical_record_json(@medical_record)
      end

      def create
        record = MedicalRecord.new(medical_record_params)
        record.organization = ActsAsTenant.current_tenant

        appointment = Appointment.find(params[:medical_record][:appointment_id])
        record.patient = appointment.patient
        record.doctor  = appointment.doctor

        record.save!

        appointment.completed!

        render json: medical_record_json(record), status: :created

      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      def update
        @medical_record.update!(medical_record_params)
        render json: medical_record_json(@medical_record)
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      private

      def set_patient
        @patient = Patient.find(params[:patient_id])
      end

      def set_medical_record
        @medical_record = MedicalRecord.find(params[:id])
      end

      def medical_record_params
        params.require(:medical_record).permit(
          :appointment_id, :weight, :height, :temperature,
          :diagnosis, :treatment, :medications, :notes, :next_visit_date
        )
      end

      def medical_record_json(record)
        {
          id:             record.id,
          appointment_id: record.appointment_id,
          patient_id:     record.patient_id,
          doctor: {
            id:        record.doctor.id,
            full_name: record.doctor.full_name
          },
          weight:          record.weight,
          height:          record.height,
          temperature:     record.temperature,
          diagnosis:       record.diagnosis,
          treatment:       record.treatment,
          medications:     record.medications,
          notes:           record.notes,
          next_visit_date: record.next_visit_date,
          created_at:      record.created_at.in_time_zone(ActsAsTenant.current_tenant.timezone).strftime("%Y-%m-%dT%H:%M:%S")
        }
      end
    end
  end
end