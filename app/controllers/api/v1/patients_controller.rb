module Api
  module V1
    class PatientsController < BaseController
      before_action :set_patient, only: [:show, :update, :destroy]

      def index
        patients = Patient.active.includes(:owner)
        patients = patients.search(params[:q]) if params[:q].present?
        render json: patients.map { |p| patient_json(p) }
      end

      def show
        render json: patient_json(@patient)
      end

      def create
        patient = Patient.new(patient_params)
        patient.save!
        render json: patient_json(patient), status: :created
      end

      def update
        @patient.update!(patient_params)
        render json: patient_json(@patient)
      end

      def destroy
        @patient.update!(status: :inactive)
        render json: { message: "Paciente desactivado correctamente" }
      end

      private

      def set_patient
        @patient = Patient.find(params[:id])
      end

      def patient_params
        params.require(:patient).permit(
          :owner_id, :name, :patient_type, :species,
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
          owner:        {
            id:        patient.owner.id,
            full_name: patient.owner.full_name,
            phone:     patient.owner.phone
          }
        }
      end
    end
  end
end