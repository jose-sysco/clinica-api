module Api
  module Public
    class VapidController < ActionController::API
      def public_key
        render json: { vapid_public_key: ENV.fetch("VAPID_PUBLIC_KEY", nil) }
      end
    end
  end
end
