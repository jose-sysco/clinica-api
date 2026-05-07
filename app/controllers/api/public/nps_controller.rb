module Api
  module Public
    class NpsController < ApplicationController
      skip_before_action :authenticate_user!
      skip_before_action :find_organization
      skip_before_action :check_suspension

      # GET /api/public/nps/:token
      def show
        survey = ActsAsTenant.without_tenant { NpsSurvey.find_by(token: params[:token]) }
        return render json: { error: "Encuesta no encontrada" }, status: :not_found unless survey

        render json: {
          submitted:    survey.submitted?,
          score:        survey.score,
          clinic_name:  survey.organization.name,
          doctor_name:  survey.appointment.doctor.full_name,
          patient_name: survey.appointment.owner&.first_name || survey.appointment.patient.name
        }
      end

      # PATCH /api/public/nps/:token
      def update
        survey = ActsAsTenant.without_tenant { NpsSurvey.find_by(token: params[:token]) }
        return render json: { error: "Encuesta no encontrada" }, status: :not_found unless survey
        return render json: { error: "Esta encuesta ya fue enviada" }, status: :unprocessable_entity if survey.submitted?

        score = params[:score].to_i
        unless (1..10).include?(score)
          return render json: { error: "Puntuación inválida (1-10)" }, status: :unprocessable_entity
        end

        ActsAsTenant.with_tenant(survey.organization) do
          survey.submit!(score: score, comment: params[:comment])
        end

        render json: { message: "¡Gracias por tu opinión!", score: survey.score }
      end
    end
  end
end
