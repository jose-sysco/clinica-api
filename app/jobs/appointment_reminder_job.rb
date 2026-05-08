class AppointmentReminderJob < ApplicationJob
  queue_as :mailers

  def perform(appointment_id)
    appointment = ActsAsTenant.without_tenant { Appointment.find(appointment_id) }
    ActsAsTenant.with_tenant(appointment.organization) do
      return unless appointment.confirmed?

      begin
        AppointmentMailer.reminder(appointment).deliver_now
      rescue => e
        Rails.logger.warn "AppointmentReminderJob mailer failed: #{e.message}"
      end
      AppointmentNotificationService.notify_reminder(appointment)
      PushNotificationService.appointment_reminder(appointment)
    end
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn "AppointmentReminderJob: Appointment #{appointment_id} not found"
  rescue => e
    Rails.logger.error "AppointmentReminderJob error: #{e.message}"
    raise
  end
end
