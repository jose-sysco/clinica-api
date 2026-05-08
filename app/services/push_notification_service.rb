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

    subscriptions = ActsAsTenant.without_tenant do
      PushSubscription.where(user: user)
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
    notify(appointment.owner || appointment.patient&.user,
           title: "Cita confirmada",
           body:  "Tu cita con #{appointment.doctor.full_name} el #{format_date(appointment.start_time)} está confirmada.",
           url:   "/reservas",
           tag:   "appt-confirmed-#{appointment.id}")
  end

  def self.appointment_cancelled(appointment)
    notify(appointment.owner || appointment.patient&.user,
           title: "Cita cancelada",
           body:  "Tu cita con #{appointment.doctor.full_name} el #{format_date(appointment.start_time)} fue cancelada.",
           url:   "/reservas",
           tag:   "appt-cancelled-#{appointment.id}")
  end

  def self.appointment_reminder(appointment)
    notify(appointment.owner || appointment.patient&.user,
           title: "Recordatorio de cita",
           body:  "Mañana tienes cita con #{appointment.doctor.full_name} a las #{appointment.start_time.strftime('%H:%M')}.",
           url:   "/reservas",
           tag:   "appt-reminder-#{appointment.id}")
  end

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
