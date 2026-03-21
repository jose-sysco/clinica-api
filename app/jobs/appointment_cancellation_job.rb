class AppointmentCancellationJob < ApplicationJob
  queue_as :mailers

  def perform(appointment_id)
    appointment = ActsAsTenant.without_tenant { Appointment.find(appointment_id) }
    ActsAsTenant.with_tenant(appointment.organization) do
      AppointmentMailer.cancellation(appointment).deliver_now
      AppointmentNotificationService.notify_cancelled(appointment)
    end
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn "AppointmentCancellationJob: Appointment #{appointment_id} not found"
  rescue => e
    Rails.logger.error "AppointmentCancellationJob error: #{e.message}"
    raise
  end
end
