module Api
  module V1
    class PushSubscriptionsController < BaseController
      # POST /api/v1/push_subscriptions
      def create
        sub = PushSubscription.find_or_initialize_by(endpoint: params[:endpoint])
        sub.assign_attributes(
          organization: ActsAsTenant.current_tenant,
          user:         current_user,
          p256dh:       params[:p256dh],
          auth:         params[:auth],
          browser:      params[:browser]
        )
        sub.save!
        render json: { message: "Suscripción registrada", id: sub.id }, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      # DELETE /api/v1/push_subscriptions
      def destroy
        sub = PushSubscription.find_by(endpoint: params[:endpoint], user: current_user)
        if sub
          sub.destroy
          head :no_content
        else
          render json: { error: "Suscripción no encontrada" }, status: :not_found
        end
      end
    end
  end
end
