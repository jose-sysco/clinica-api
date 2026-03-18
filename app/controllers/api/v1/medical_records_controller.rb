module Api
  module V1
    class MedicalRecordsController < BaseController
      before_action :set_patient,        only: [:patient_records]
      before_action :set_medical_record, only: [:show, :update]

      # GET /api/v1/medical_records — todos los expedientes de la org (paginado)
      def index
        scope = MedicalRecord.includes(:doctor, :patient).order(created_at: :desc)
        scope = scope.where(patient_id: params[:patient_id]) if params[:patient_id].present?
        pagy, records = pagy(scope, limit: params[:per_page] || 20)
        render json: {
          data:       records.map { |r| medical_record_json(r) },
          pagination: pagy_metadata(pagy)
        }
      end

      # GET /api/v1/patients/:patient_id/medical_records
      def patient_records
        records = @patient.medical_records
                          .includes(:doctor)
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
          :appointment_id,
          :weight, :height, :temperature,
          :heart_rate, :respiratory_rate,
          :blood_pressure_systolic, :blood_pressure_diastolic,
          :oxygen_saturation,
          :soap_subjective, :soap_objective, :soap_assessment, :soap_plan,
          :diagnosis, :treatment, :medications, :notes,
          :next_visit_date
        )
      end

      def medical_record_json(record)
        tz = ActsAsTenant.current_tenant.timezone
        {
          id:             record.id,
          appointment_id: record.appointment_id,
          patient_id:     record.patient_id,
          patient:        record.association(:patient).loaded? ? { id: record.patient.id, name: record.patient.name } : nil,
          doctor: {
            id:        record.doctor.id,
            full_name: record.doctor.full_name
          },
          # Signos vitales
          weight:                   record.weight,
          height:                   record.height,
          temperature:              record.temperature,
          heart_rate:               record.heart_rate,
          respiratory_rate:         record.respiratory_rate,
          blood_pressure_systolic:  record.blood_pressure_systolic,
          blood_pressure_diastolic: record.blood_pressure_diastolic,
          oxygen_saturation:        record.oxygen_saturation,
          # SOAP
          soap_subjective: record.soap_subjective,
          soap_objective:  record.soap_objective,
          soap_assessment: record.soap_assessment,
          soap_plan:       record.soap_plan,
          # Campos legacy
          diagnosis:       record.diagnosis,
          treatment:       record.treatment,
          medications:     record.medications,
          notes:           record.notes,
          next_visit_date: record.next_visit_date,
          created_at:      record.created_at.in_time_zone(tz).strftime("%Y-%m-%dT%H:%M:%S")
        }
      end
    end
  end
end
