class AppointmentConfirmationJob < ApplicationJob
  queue_as :mailers

  def perform(appointment_id)
    appointment = Appointment.find(appointment_id)
    AppointmentMailer.confirmation(appointment).deliver_now
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn "AppointmentConfirmationJob: Appointment #{appointment_id} not found"
  end
end