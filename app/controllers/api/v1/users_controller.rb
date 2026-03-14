module Api
  module V1
    class UsersController < BaseController
      def me
        render json: user_json(current_user)
      end

      def update_me
        current_user.update!(me_params)
        render json: user_json(current_user)
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      def change_password
        unless current_user.valid_password?(params[:current_password])
            render json: { error: "Contraseña actual incorrecta" }, status: :unprocessable_entity
            return
        end

        if params[:password] != params[:password_confirmation]
            render json: { error: "Las contraseñas no coinciden" }, statuts: :unprocessable_entity
            return 
        end

        current_user.update!(
            password: params[:password],
            password_confirmation: params[:password_confirmation]
        )

        render json: { message: "Contraseña actualizada correctamente" }, status: :ok
        rescue ActiveRecord::RecordInvalid => e
            render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
        end

      private

      def me_params
        params.require(:user).permit(
          :first_name, :last_name, :phone, :avatar
        )
      end

      def user_json(user)
        {
          id:           user.id,
          email:        user.email,
          first_name:   user.first_name,
          last_name:    user.last_name,
          full_name:    user.full_name,
          phone:        user.phone,
          role:         user.role,
          status:       user.status,
          avatar:       user.avatar,
          organization: {
            id:          user.organization.id,
            name:        user.organization.name,
            slug:        user.organization.slug,
            clinic_type: user.organization.clinic_type
          },
          created_at: user.created_at
        }
      end
    end
  end
end