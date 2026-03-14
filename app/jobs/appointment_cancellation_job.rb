class AppointmentCancellationJob < ApplicationJob
  queue_as :mailers

  def perform(appointment_id)
    appointment = Appointment.find(appointment_id)
    AppointmentMailer.cancellation(appointment).deliver_now
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn "AppointmentCancellationJob: Appointment #{appointment_id} not found"
  end
end