module Api
  module Superadmin
    class UsersController < BaseController
      def index
        ActsAsTenant.without_tenant do
          users = User.where(role: :superadmin).order(created_at: :desc)
          render json: { data: users.map { |u| user_json(u) } }
        end
      end

      def create
        ActsAsTenant.without_tenant do
          superadmin_org = Organization.find_by!(slug: "clinicaportal-admin")

          user = User.new(user_params)
          user.organization    = superadmin_org
          user.role            = :superadmin
          user.status          = :active
          user.email_verified_at = Time.current  # creado por superadmin: pre-verificado
          user.save!

          render json: user_json(user), status: :created
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Organización de administración no encontrada" }, status: :unprocessable_entity
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      def update
        ActsAsTenant.without_tenant do
          user = User.where(role: :superadmin).find(params[:id])
          user.update!(update_params)
          render json: user_json(user)
        end
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      private

      def user_params
        params.require(:user).permit(:first_name, :last_name, :email, :phone, :password, :password_confirmation)
      end

      def update_params
        params.require(:user).permit(:first_name, :last_name, :phone, :status)
      end

      def user_json(user)
        {
          id:         user.id,
          full_name:  user.full_name,
          first_name: user.first_name,
          last_name:  user.last_name,
          email:      user.email,
          phone:      user.phone,
          status:     user.status,
          created_at: user.created_at
        }
      end
    end
  end
end
