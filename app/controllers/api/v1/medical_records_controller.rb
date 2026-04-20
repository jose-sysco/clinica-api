module Api
  module V1
    class MedicalRecordsController < BaseController
      before_action :set_patient,        only: [ :patient_records ]
      before_action :set_medical_record, only: [ :show, :update ]

      # GET /api/v1/medical_records — todos los expedientes de la org (paginado)
      def index
        authorize MedicalRecord, policy_class: MedicalRecordPolicy
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
        authorize MedicalRecord, policy_class: MedicalRecordPolicy
        records = @patient.medical_records
                          .includes(:doctor)
                          .order(created_at: :desc)
        render json: records.map { |r| medical_record_json(r) }
      end

      def show
        authorize @medical_record, policy_class: MedicalRecordPolicy
        render json: medical_record_json(@medical_record)
      end

      def create
        authorize MedicalRecord, policy_class: MedicalRecordPolicy
        record = MedicalRecord.new(medical_record_params)
        record.organization = ActsAsTenant.current_tenant

        appointment = Appointment.find(params[:medical_record][:appointment_id])
        record.patient = appointment.patient
        record.doctor  = appointment.doctor

        record.save!

        appointment.completed!

        # Auto-deduct inventory if doctor has inventory_movements enabled
        used = Array(params[:medical_record][:used_products])
        if used.any? && record.doctor&.inventory_movements?
          used.each do |entry|
            product = Product.find_by(id: entry[:product_id])
            next unless product && entry[:quantity].to_f > 0

            product.stock_movements.create!(
              organization:    ActsAsTenant.current_tenant,
              user:            current_user,
              doctor:          record.doctor,
              medical_record:  record,
              movement_type:   :exit,
              quantity:        entry[:quantity].to_f,
              notes:           "Consulta ##{appointment.id} — #{record.doctor.full_name}"
            )
          rescue ActiveRecord::RecordInvalid
            # Don't fail the whole record if stock is already 0 — just skip
          end
        end

        render json: medical_record_json(record), status: :created

      rescue ActiveRecord::RecordNotFound
        render json: { error: "Cita no encontrada" }, status: :not_found
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      def update
        authorize @medical_record, policy_class: MedicalRecordPolicy
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
          # Vitales generales
          :weight, :height, :temperature,
          :heart_rate, :respiratory_rate,
          :blood_pressure_systolic, :blood_pressure_diastolic,
          :oxygen_saturation,
          # SOAP
          :soap_subjective, :soap_objective, :soap_assessment, :soap_plan,
          # Campos legacy / generales
          :diagnosis, :treatment, :medications, :notes,
          :next_visit_date,
          # Fisioterapia
          :pain_scale, :affected_area, :range_of_motion,
          :functional_assessment, :treatment_performed,
          :rehabilitation_plan, :evolution_notes,
          # Odontología
          :dental_procedure, :dental_affected_teeth, :dental_anesthesia,
          # Psicología
          :session_number, :mood_scale, :psychotherapy_technique,
          :session_objectives, :session_development, :session_agreements,
          # Nutrición
          :goal_weight, :dietary_assessment, :dietary_plan,
          :food_restrictions, :physical_activity_level,
          # Veterinaria
          :coat_condition, :vaccination_notes, :deworming_notes
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
          # Vitales generales
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
          # Generales / legacy
          diagnosis:       record.diagnosis,
          treatment:       record.treatment,
          medications:     record.medications,
          notes:           record.notes,
          next_visit_date: record.next_visit_date,
          # Fisioterapia
          pain_scale:              record.pain_scale,
          affected_area:           record.affected_area,
          range_of_motion:         record.range_of_motion,
          functional_assessment:   record.functional_assessment,
          treatment_performed:     record.treatment_performed,
          rehabilitation_plan:     record.rehabilitation_plan,
          evolution_notes:         record.evolution_notes,
          # Odontología
          dental_procedure:        record.dental_procedure,
          dental_affected_teeth:   record.dental_affected_teeth,
          dental_anesthesia:       record.dental_anesthesia,
          # Psicología
          session_number:          record.session_number,
          mood_scale:              record.mood_scale,
          psychotherapy_technique: record.psychotherapy_technique,
          session_objectives:      record.session_objectives,
          session_development:     record.session_development,
          session_agreements:      record.session_agreements,
          # Nutrición
          goal_weight:             record.goal_weight,
          dietary_assessment:      record.dietary_assessment,
          dietary_plan:            record.dietary_plan,
          food_restrictions:       record.food_restrictions,
          physical_activity_level: record.physical_activity_level,
          # Veterinaria
          coat_condition:          record.coat_condition,
          vaccination_notes:       record.vaccination_notes,
          deworming_notes:         record.deworming_notes,
          created_at:              record.created_at.in_time_zone(tz).strftime("%Y-%m-%dT%H:%M:%S")
        }
      end
    end
  end
end
