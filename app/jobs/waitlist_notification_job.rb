class WaitlistNotificationJob < ApplicationJob
  queue_as :default

  def perform(appointment_id)
    appointment = Appointment.find_by(id: appointment_id)
    return unless appointment&.cancelled?

    # Busca el siguiente en espera para este doctor
    entry = WaitlistEntry
      .where(organization_id: appointment.organization_id, doctor_id: appointment.doctor_id, status: :waiting)
      .order(:created_at)
      .first

    return unless entry

    entry.notify!

    # Crea una notificación in-app para el staff
    Notification.create!(
      organization_id: appointment.organization_id,
      user_id:         appointment.organization.users.where(role: [:admin, :staff]).first&.id,
      appointment_id:  appointment.id,
      notification_type: :reminder,
      channel:         :push,
      status:          :pending,
      message:         "Cita liberada — #{entry.patient.name} está en lista de espera con #{appointment.doctor.full_name}. Puedes contactarle para agendar."
    )

    Rails.logger.info "Lista de espera: notificado #{entry.patient.name} por cita cancelada ##{appointment.id}"
  rescue => e
    Rails.logger.error "WaitlistNotificationJob error: #{e.message}"
  end
end
