module Api
  module V1
    class PatientsController < BaseController
      before_action :set_owner
      before_action :set_patient, only: [:show, :update, :destroy]

      def index
        authorize Patient, policy_class: PatientPolicy
        patients = @owner.patients
        patients = patients.search(params[:q]) if params[:q].present?
        render json: patients.map { |p| patient_json(p) }
      end

      def show
        authorize @patient, policy_class: PatientPolicy
        render json: patient_json(@patient)
      end

      def create
        authorize Patient, policy_class: PatientPolicy
        patient = @owner.patients.new(patient_params)
        patient.save!
        render json: patient_json(patient), status: :created
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
        @owner = Owner.find(params[:owner_id])
      end

      def set_patient
        @patient = @owner.patients.find(params[:id])
      end

      def patient_params
        params.require(:patient).permit(
          :name, :patient_type, :species,
          :breed, :gender, :birthdate, :weight, :notes, :status
        )
      end

      def patient_json(patient)
        {
          id:           patient.id,
          name:         patient.name,
          patient_type: patient.patient_type,
          species:      patient.species,
          breed:        patient.breed,
          gender:       patient.gender,
          birthdate:    patient.birthdate,
          age:          patient.age,
          weight:       patient.weight,
          notes:        patient.notes,
          status:       patient.status,
          owner: {
            id:        patient.owner.id,
            full_name: patient.owner.full_name,
            phone:     patient.owner.phone
          }
        }
      end
    end
  end
end