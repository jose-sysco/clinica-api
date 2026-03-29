class AppointmentMailer < ApplicationMailer
  def confirmation(appointment)
    @appointment = appointment
    @patient     = appointment.patient
    @doctor      = appointment.doctor
    @owner       = appointment.owner
    @organization = appointment.organization

    mail(
      to:      @owner.email,
      subject: "✅ Cita confirmada - #{@organization.name}"
    )
  end

  def reminder(appointment)
    @appointment  = appointment
    @patient      = appointment.patient
    @doctor       = appointment.doctor
    @owner        = appointment.owner
    @organization = appointment.organization

    mail(
      to:      @owner.email,
      subject: "⏰ Recordatorio de cita - #{@organization.name}"
    )
  end

  def cancellation(appointment)
    @appointment  = appointment
    @patient      = appointment.patient
    @doctor       = appointment.doctor
    @owner        = appointment.owner
    @organization = appointment.organization

    mail(
      to:      @owner.email,
      subject: "❌ Cita cancelada - #{@organization.name}"
    )
  end
end
