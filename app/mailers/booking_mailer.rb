class BookingMailer < ApplicationMailer
  # Al paciente: "Tu solicitud fue recibida, espera confirmación"
  def request_received(appointment, owner_email, owner_name, admission_url = nil)
    @appointment   = appointment
    @doctor        = appointment.doctor
    @organization  = appointment.organization
    @owner_name    = owner_name
    @admission_url = admission_url

    mail(
      to:      owner_email,
      subject: "Solicitud de cita recibida — #{@organization.name}"
    )
  end

  # A la clínica: "Nueva solicitud de cita de {nombre}"
  def new_request(appointment, admin_emails, owner_name, owner_phone)
    @appointment  = appointment
    @doctor       = appointment.doctor
    @organization = appointment.organization
    @owner_name   = owner_name
    @owner_phone  = owner_phone

    mail(
      to:      admin_emails,
      subject: "Nueva solicitud de cita — #{owner_name}"
    )
  end
end
