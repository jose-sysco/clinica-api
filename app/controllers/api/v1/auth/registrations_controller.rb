module Api
  module V1
    module Auth
      class RegistrationsController < ApplicationController
        skip_before_action :authenticate_user!, only: [:create]
        skip_before_action :set_tenant, only: [:create]

        def create
          ActiveRecord::Base.transaction do
            @organization = Organization.new(organization_params)
            @organization.save!

            @user = User.new(user_params)
            @user.organization = @organization
            @user.role = :admin
            @user.status = :active
            @user.save!
          end

          render json: {
            message: "Registro exitoso",
            organization: organization_json(@organization),
            user: user_json(@user)
          }, status: :created

        rescue ActiveRecord::RecordInvalid => e
          render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
        end

        def create_staff
          ActiveRecord::Base.transaction do
            @user = User.new(staff_params)
            @user.organization = ActsAsTenant.current_tenant
            @user.status = :active
            @user.save!

            # Solo crea el Doctor stub cuando se usa este endpoint directamente
            # (ej: desde gestión de usuarios). El flujo /dashboard/doctors/new
            # usa DoctorsController#create que maneja todo en su propia transacción.
            if @user.role == "doctor"
              Doctor.create!(
                organization:          ActsAsTenant.current_tenant,
                user:                  @user,
                specialty:             "Pendiente de definir",
                consultation_duration: 30,
                status:                :active
              )
            end
          end

          render json: {
            message: "Usuario creado correctamente",
            user: {
              id:        @user.id,
              email:     @user.email,
              full_name: @user.full_name,
              role:      @user.role
            }
          }, status: :created

        rescue ActiveRecord::RecordInvalid => e
          render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
        end

        private

        def organization_params
          params.require(:organization).permit(
            :name, :subdomain, :email, :phone,
            :address, :city, :country, :timezone, :clinic_type
          )
        end

        def user_params
          params.require(:user).permit(
            :first_name, :last_name, :email, :phone,
            :password, :password_confirmation
          )
        end

        def organization_json(org)
          {
            id:                   org.id,
            name:                 org.name,
            slug:                 org.slug,
            subdomain:            org.subdomain,
            email:                org.email,
            clinic_type:          org.clinic_type,
            status:               org.status,
            plan:                 org.plan,
            trial_ends_at:        org.trial_ends_at,
            trial_days_remaining: org.trial_days_remaining,
            trial_expired:        org.trial_expired?,
            on_trial:             org.trial?
          }
        end

        def user_json(user)
          {
            id:        user.id,
            email:     user.email,
            full_name: user.full_name,
            role:      user.role,
            status:    user.status
          }
        end

        def staff_params
          params.require(:user).permit(
            :first_name, :last_name, :email, :phone,
            :password, :password_confirmation, :role
          )
        end
      end
    end
  end
end