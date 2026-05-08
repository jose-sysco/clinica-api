class PushNotificationService
  VAPID_KEYS = {
    public_key:  ENV.fetch("VAPID_PUBLIC_KEY",  nil),
    private_key: ENV.fetch("VAPID_PRIVATE_KEY", nil),
    subject:     ENV.fetch("VAPID_SUBJECT",      "mailto:admin@agendia.sysco.com.gt")
  }.freeze

  # Send a push notification to all subscriptions for the given user.
  # payload keys: title (required), body, url, tag
  def self.notify(user, payload)
    return unless VAPID_KEYS[:public_key] && VAPID_KEYS[:private_key]
    return if user.nil?

    subscriptions = ActsAsTenant.without_tenant do
      PushSubscription.where(user: user)
    end

    if subscriptions.empty?
      Rails.logger.info("[PushNotification] No subscriptions for user #{user.id}")
      return
    end

    message = JSON.generate(payload)

    subscriptions.each do |sub|
      Webpush.payload_send(
        message:     message,
        endpoint:    sub.endpoint,
        p256dh:      sub.p256dh,
        auth:        sub.auth,
        vapid:       VAPID_KEYS,
        ttl:         86_400
      )
    rescue Webpush::InvalidSubscription, Webpush::ExpiredSubscription
      sub.destroy
    rescue StandardError => e
      Rails.logger.error("[PushNotification] Error sending to #{sub.endpoint}: #{e.message}")
    end
  end

  # Convenience wrappers for appointment events
  def self.appointment_confirmed(appointment)
    notify_appointment_users(appointment,
           title: "Cita confirmada",
           body:  "Cita con #{appointment.doctor.full_name} el #{format_date(appointment.scheduled_at)} confirmada.",
           url:   "/dashboard/citas",
           tag:   "appt-confirmed-#{appointment.id}")
  end

  def self.appointment_cancelled(appointment)
    notify_appointment_users(appointment,
           title: "Cita cancelada",
           body:  "Cita con #{appointment.doctor.full_name} el #{format_date(appointment.scheduled_at)} fue cancelada.",
           url:   "/dashboard/citas",
           tag:   "appt-cancelled-#{appointment.id}")
  end

  def self.appointment_reminder(appointment)
    notify_appointment_users(appointment,
           title: "Recordatorio de cita",
           body:  "Mañana: cita con #{appointment.doctor.full_name} a las #{appointment.scheduled_at.strftime('%H:%M')}.",
           url:   "/dashboard/citas",
           tag:   "appt-reminder-#{appointment.id}")
  end

  # Notify the patient/owner user + all admins in the org
  def self.notify_appointment_users(appointment, payload)
    patient_user = appointment.patient&.user
    notify(patient_user, payload) if patient_user

    ActsAsTenant.with_tenant(appointment.organization) do
      User.where(role: :admin).each { |admin| notify(admin, payload) }
    end
  end
  private_class_method :notify_appointment_users

  def self.low_stock(product)
    # Notify all admin users in the org
    ActsAsTenant.with_tenant(product.organization) do
      User.where(role: :admin).each do |admin|
        notify(admin,
               title: "Stock bajo: #{product.name}",
               body:  "Quedan #{product.current_stock} #{product.unit} en inventario.",
               url:   "/dashboard/inventario",
               tag:   "low-stock-#{product.id}")
      end
    end
  end

  def self.format_date(time)
    time.strftime("%d/%m/%Y %H:%M")
  end
  private_class_method :format_date
end
