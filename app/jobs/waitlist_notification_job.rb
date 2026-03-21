class WaitlistNotificationJob < ApplicationJob
  queue_as :default

  def perform(appointment_id)
    appointment = ActsAsTenant.without_tenant { Appointment.find_by(id: appointment_id) }
    return unless appointment&.cancelled?

    ActsAsTenant.with_tenant(appointment.organization) do
      # Busca el siguiente en espera para este doctor
      entry = WaitlistEntry
        .where(doctor_id: appointment.doctor_id, status: :waiting)
        .order(:created_at)
        .first

      return unless entry

      entry.notify!

      # Crea una notificación in-app para el staff
      staff_user = appointment.organization.users.where(role: [:admin, :receptionist]).first
      return unless staff_user

      Notification.create!(
        user_id:           staff_user.id,
        appointment_id:    appointment.id,
        notification_type: :reminder,
        channel:           :push,
        status:            :pending,
        message:           "Cita liberada — #{entry.patient.name} está en lista de espera con #{appointment.doctor.full_name}. Puedes contactarle para agendar."
      )

      Rails.logger.info "Lista de espera: notificado #{entry.patient.name} por cita cancelada ##{appointment.id}"
    end
  rescue => e
    Rails.logger.error "WaitlistNotificationJob error: #{e.message}"
  end
end
