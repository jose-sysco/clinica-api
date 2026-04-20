module Api
  module V1
    class PatientsController < BaseController
      before_action :set_owner,          only: [ :show, :update, :destroy, :create ]
      # set_owner is a no-op when owner_id param is absent (standalone patient creation)
      before_action :set_patient,        only: [ :show, :update, :destroy ]
      before_action :check_patient_limit, only: [ :create ]

      def index
        authorize Patient, policy_class: PatientPolicy

        patients = if params[:owner_id]
          Owner.find(params[:owner_id]).patients
        else
          Patient.active.includes(:owner)
        end

        patients = patients.search(params[:q]) if params[:q].present?
        pagy, patients = pagy(patients, limit: params[:per_page] || 10)

        render json: {
          data:       patients.map { |p| patient_json(p) },
          pagination: pagy_metadata(pagy)
        }
      end

      def show
        patient = Patient.find(params[:id])
        authorize patient, policy_class: PatientPolicy
        render json: patient_json(patient)
      end

      def create
        authorize Patient, policy_class: PatientPolicy
        patient = if @owner
          @owner.patients.new(patient_params)
        else
          p = Patient.new(patient_params)
          p.organization = ActsAsTenant.current_tenant
          p
        end
        patient.save!
        render json: patient_json(patient), status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      def update
        authorize @patient, policy_class: PatientPolicy
        @patient.update!(patient_params)
        render json: patient_json(@patient)
      end

      def destroy
        authorize @patient, policy_class: PatientPolicy
        @patient.update!(status: :inactive)
        render json: { message: "Paciente desactivado correctamente" }
      end

      private

      def set_owner
        @owner = Owner.find(params[:owner_id]) if params[:owner_id]
      end

      def check_patient_limit
        config = PlanConfiguration.find_by(plan: ActsAsTenant.current_tenant.plan)
        return unless config&.max_patients

        if Patient.active.count >= config.max_patients
          render json: {
            error: "Has alcanzado el límite de #{config.max_patients} pacientes para tu plan #{config.display_name}. Actualiza tu plan para agregar más.",
            code:  "patient_limit_reached"
          }, status: :forbidden
        end
      end

      def set_patient
        @patient = @owner ? @owner.patients.find(params[:id]) : Patient.find(params[:id])
      end

      def patient_params
        params.require(:patient).permit(
          :name, :patient_type, :species,
          :breed, :gender, :birthdate, :weight, :notes, :status,
          :blood_type, :allergies, :chronic_conditions,
          :microchip_number, :reproductive_status
        )
      end

      def patient_json(patient)
        {
          id:                   patient.id,
          name:                 patient.name,
          patient_type:         patient.patient_type,
          species:              patient.species,
          breed:                patient.breed,
          gender:               patient.gender,
          birthdate:            patient.birthdate,
          age:                  patient.age,
          weight:               patient.weight,
          notes:                patient.notes,
          status:               patient.status,
          blood_type:           patient.blood_type,
          allergies:            patient.allergies,
          chronic_conditions:   patient.chronic_conditions,
          microchip_number:     patient.microchip_number,
          reproductive_status:  patient.reproductive_status,
          owner: patient.owner ? {
            id:        patient.owner.id,
            full_name: patient.owner.full_name,
            phone:     patient.owner.phone
          } : nil
        }
      end
    end
  end
end
