class AppointmentReminderJob < ApplicationJob
  queue_as :mailers

  def perform(appointment_id)
    appointment = Appointment.find(appointment_id)
    return unless appointment.confirmed?

    AppointmentMailer.reminder(appointment).deliver_now
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn "AppointmentReminderJob: Appointment #{appointment_id} not found"
  end
end