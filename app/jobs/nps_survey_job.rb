class NpsSurveyJob < ApplicationJob
  queue_as :default

  def perform(appointment_id)
    appointment = ActsAsTenant.without_tenant { Appointment.find_by(id: appointment_id) }
    return unless appointment
    return unless appointment.completed?

    owner = appointment.owner
    return unless owner&.email.present?

    ActsAsTenant.with_tenant(appointment.organization) do
      return if appointment.nps_survey.present?

      survey = NpsSurvey.create!(appointment: appointment)
      survey_url = "#{ENV.fetch('FRONTEND_URL', 'http://localhost:3000')}/reservas/nps/#{survey.token}"
      NpsMailer.survey(appointment, owner.email, survey_url).deliver_now
    end
  end
end
