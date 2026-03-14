module Api
  module V1
    class OwnersController < BaseController
      before_action :set_owner, only: [:show, :update, :destroy]

      def index
        authorize Owner, policy_class: OwnerPolicy
        owners = Owner.all
        owners = owners.search(params[:q]) if params[:q].present?

        pagy, owners = pagy(owners, limit: params[:per_page] || 20)

        render json: {
          data:       owners.map { |o| owner_json(o) },
          pagination: pagy_metadata(pagy)
        }
      end

      def show
        authorize @owner, policy_class: OwnerPolicy
        render json: owner_json(@owner)
      end

      def create
        authorize Owner, policy_class: OwnerPolicy
        owner = Owner.new(owner_params)
        owner.save!
        render json: owner_json(owner), status: :created
      end

      def update
        authorize @owner, policy_class: OwnerPolicy
        @owner.update!(owner_params)
        render json: owner_json(@owner)
      end

      def destroy
        authorize @owner, policy_class: OwnerPolicy
        @owner.destroy!
        render json: { message: "Propietario eliminado correctamente" }
      end

      private

      def set_owner
        @owner = Owner.find(params[:id])
      end

      def owner_params
        params.require(:owner).permit(
          :user_id, :first_name, :last_name,
          :email, :phone, :address, :identification
        )
      end

      def owner_json(owner)
        {
          id:             owner.id,
          full_name:      owner.full_name,
          email:          owner.email,
          phone:          owner.phone,
          address:        owner.address,
          identification: owner.identification,
          patients_count: owner.patients.count
        }
      end
    end
  end
end