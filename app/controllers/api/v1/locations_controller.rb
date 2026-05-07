module Api
  module V1
    class LocationsController < ApplicationController
      before_action :require_multi_location_feature!, only: [ :create, :update, :destroy ]
      before_action :set_location, only: [ :show, :update, :destroy ]

      # GET /api/v1/locations
      def index
        authorize Location, policy_class: LocationPolicy
        locations = Location.all.order(:name)
        render json: locations.map { |l| location_json(l) }
      end

      # GET /api/v1/locations/:id
      def show
        authorize @location, policy_class: LocationPolicy
        render json: location_json(@location)
      end

      # POST /api/v1/locations
      def create
        authorize Location, policy_class: LocationPolicy
        location = Location.new(location_params)
        location.organization = ActsAsTenant.current_tenant
        if location.save
          render json: location_json(location), status: :created
        else
          render json: { errors: location.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/locations/:id
      def update
        authorize @location, policy_class: LocationPolicy
        if @location.update(location_params)
          render json: location_json(@location)
        else
          render json: { errors: @location.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/locations/:id
      def destroy
        authorize @location, policy_class: LocationPolicy
        @location.update!(active: false)
        head :no_content
      end

      private

      def set_location
        @location = Location.find(params[:id])
      end

      def location_params
        params.require(:location).permit(:name, :address, :city, :phone, :active)
      end

      def require_multi_location_feature!
        unless ActsAsTenant.current_tenant.enabled_features.include?("multi_location")
          render json: { error: "Las sedes múltiples no están disponibles en tu plan actual.", code: "feature_not_available" },
                 status: :payment_required
        end
      end

      def location_json(loc)
        {
          id:      loc.id,
          name:    loc.name,
          address: loc.address,
          city:    loc.city,
          phone:   loc.phone,
          active:  loc.active,
          doctors_count: loc.doctors.count
        }
      end
    end
  end
end
