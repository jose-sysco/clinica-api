module Api
  module V1
    class NotificationsController < BaseController
      before_action :set_notification, only: [ :show, :mark_as_read ]

      def index
        notifications = current_user.notifications
                                    .order(created_at: :desc)
        render json: notifications.map { |n| notification_json(n) }
      end

      def show
        render json: notification_json(@notification)
      end

      def mark_as_read
        @notification.mark_as_read!
        render json: { message: "Notificación marcada como leída" }
      end

      def mark_all_as_read
        current_user.notifications.unread.each(&:mark_as_read!)
        render json: { message: "Todas las notificaciones marcadas como leídas" }
      end

      private

      def set_notification
        @notification = current_user.notifications.find(params[:id])
      end

      def notification_json(notification)
        {
          id:                notification.id,
          notification_type: notification.notification_type,
          channel:           notification.channel,
          status:            notification.status,
          message:           notification.message,
          sent_at:           notification.sent_at,
          read_at:           notification.read_at,
          appointment_id:    notification.appointment_id,
          created_at:        notification.created_at
        }
      end
    end
  end
end
