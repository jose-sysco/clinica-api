module Api
    module V1
        module Auth
            class RegistrationsController < Devise::RegistrationsController
                respond_to :json

                skip_before_action :authenticate_user!, only: [:create]

                private 

                def respond_with(resource, _opts = {})
                    if resource.persisted?
                        render json: {
                            message: "Usuario creado correctamente",
                            user: {
                                id: resource.id,
                                email: resource.email,
                                full_name: resource.full_name,
                                role: resource.role,
                            }
                        }, status: :created
                    else
                        render json { errors: resource.errors.full_messages}, status: :unprocessable_entity
                    end
                end

                def sign_up_params
                    params.require(:user).permit(
                        :email, :password, :password_confirmation,
                        :first_name, :last_name, :phone, :role
                    )
                end
            end
        end
    end
end