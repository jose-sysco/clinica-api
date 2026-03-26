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
          render json: { error: 'Contraseña actual incorrecta' }, status: :unprocessable_entity
          return
        end

        if params[:password] != params[:password_confirmation]
          render json: { error: 'Las contraseñas no coinciden' }, status: :unprocessable_entity
          return
        end

        current_user.update!(
          password:              params[:password],
          password_confirmation: params[:password_confirmation]
        )
        render json: { message: 'Contraseña actualizada correctamente' }, status: :ok
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      # Admin — lista todos los usuarios de la organización
      def index
        authorize User
        users = User.all.order(created_at: :desc)
        pagy, users = pagy(users, limit: params[:per_page] || 10)
        render json: { data: users.map { |u| user_json(u) }, pagination: pagy_metadata(pagy) }
      end

      # Admin — ver un usuario
      def show
        authorize User
        user = User.find(params[:id])
        render json: user_json(user)
      end

      # Admin — actualizar usuario
      def update
        authorize User
        user = User.find(params[:id])
        user.update!(admin_user_params)
        render json: user_json(user)
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      # Admin — cambiar contraseña de cualquier usuario
      def admin_change_password
        authorize User
        user = User.find(params[:id])

        if params[:password] != params[:password_confirmation]
          render json: { error: 'Las contraseñas no coinciden' }, status: :unprocessable_entity
          return
        end

        user.update!(
          password:              params[:password],
          password_confirmation: params[:password_confirmation]
        )
        render json: { message: 'Contraseña actualizada correctamente' }, status: :ok
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      private

      def me_params
        params.require(:user).permit(:first_name, :last_name, :phone, :avatar)
      end

      def admin_user_params
        params.require(:user).permit(:first_name, :last_name, :phone, :role, :status)
      end

      def user_json(user)
        {
          id:         user.id,
          email:      user.email,
          first_name: user.first_name,
          last_name:  user.last_name,
          full_name:  user.full_name,
          phone:      user.phone,
          role:       user.role,
          status:     user.status,
          avatar:     user.avatar,
          doctor_id:  user.doctor? ? user.doctor&.id : nil,
          organization: {
            id:                   user.organization.id,
            name:                 user.organization.name,
            slug:                 user.organization.slug,
            subdomain:            user.organization.subdomain,
            email:                user.organization.email,
            phone:                user.organization.phone,
            address:              user.organization.address,
            city:                 user.organization.city,
            country:              user.organization.country,
            timezone:             user.organization.timezone,
            clinic_type:          user.organization.clinic_type,
            status:               user.organization.status,
            plan:                 user.organization.plan,
            trial_ends_at:        user.organization.trial_ends_at,
            trial_days_remaining: user.organization.trial_days_remaining,
            trial_expired:        user.organization.trial_expired?,
            on_trial:             user.organization.trial?,
            features:             user.organization.enabled_features,
            logo_url:             user.organization.logo_file.attached? \
                                    ? rails_blob_url(user.organization.logo_file, host: request.base_url) \
                                    : user.organization.logo,
          }.merge(plan_config_for(user.organization)),
          created_at: user.created_at
        }
      end
    end
  end
end