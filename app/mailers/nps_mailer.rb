class NpsMailer < ApplicationMailer
  def survey(appointment, recipient_email, survey_url)
    @appointment = appointment
    @survey_url  = survey_url
    @clinic_name = appointment.organization.name
    @patient_name = appointment.owner&.first_name || appointment.patient.name
    @doctor_name  = appointment.doctor.full_name

    mail(
      to:      recipient_email,
      subject: "¿Cómo fue tu visita a #{@clinic_name}?"
    )
  end
end
