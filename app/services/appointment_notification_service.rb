class AppointmentNotificationService
  def self.notify_confirmed(appointment)
    new(appointment).notify_confirmed
  end

  def self.notify_cancelled(appointment)
    new(appointment).notify_cancelled
  end

  def self.notify_reminder(appointment)
    new(appointment).notify_reminder
  end

  def initialize(appointment)
    @appointment = appointment
  end

  def notify_confirmed
    # Notifica al doctor: su agenda acaba de actualizarse
    create_for_user(
      user_id:           @appointment.doctor.user_id,
      notification_type: :confirmation,
      message:           "Cita confirmada: #{patient_name} el #{formatted_date} a las #{formatted_time}."
    )
  end

  def notify_cancelled
    # Notifica al doctor
    create_for_user(
      user_id:           @appointment.doctor.user_id,
      notification_type: :cancellation,
      message:           "Cita cancelada: #{patient_name} tenía cita el #{formatted_date} a las #{formatted_time}."
    )

    # Notifica a admin y recepcionistas
    staff_users.each do |user|
      create_for_user(
        user_id:           user.id,
        notification_type: :cancellation,
        message:           "Cita cancelada — #{patient_name} con #{doctor_name} el #{formatted_date}. Slot disponible."
      )
    end
  end

  def notify_reminder
    # Recordatorio al doctor el día previo
    create_for_user(
      user_id:           @appointment.doctor.user_id,
      notification_type: :reminder,
      message:           "Recordatorio: mañana tienes cita con #{patient_name} a las #{formatted_time}."
    )
  end

  private

  def create_for_user(user_id:, notification_type:, message:)
    Notification.create!(
      user_id:           user_id,
      appointment_id:    @appointment.id,
      notification_type: notification_type,
      channel:           :push,
      status:            :sent,
      message:           message
    )
  rescue => e
    Rails.logger.error "AppointmentNotificationService error (user #{user_id}): #{e.message}"
  end

  def staff_users
    User.where(role: [ :admin, :receptionist ])
        .where.not(id: @appointment.doctor.user_id)
  end

  def patient_name
    @appointment.patient.name
  end

  def doctor_name
    @appointment.doctor.full_name
  end

  def formatted_date
    @appointment.scheduled_at.strftime("%-d de %B")
  end

  def formatted_time
    @appointment.scheduled_at.strftime("%H:%M")
  end
end
