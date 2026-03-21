class AppointmentConfirmationJob < ApplicationJob
  queue_as :mailers

  def perform(appointment_id)
    appointment = ActsAsTenant.without_tenant { Appointment.find(appointment_id) }
    ActsAsTenant.with_tenant(appointment.organization) do
      AppointmentMailer.confirmation(appointment).deliver_now
      AppointmentNotificationService.notify_confirmed(appointment)
    end
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn "AppointmentConfirmationJob: Appointment #{appointment_id} not found"
  rescue => e
    Rails.logger.error "AppointmentConfirmationJob error: #{e.message}"
    raise
  end
end