module Api
    module V1
        module Auth
            class SessionsController < Devise::SesionsController
                respond_to :json

                skip_before_action :authenticate_user!, only: [:create]
                skip_before_action :verify_signed_out_user

                private

                def respond_with(resource, _opts ={})
                    if resource.persisted?
                        render json: {
                            message: "Sesión iniciada correctamente",
                            user: {
                                id: resource.id,
                                email: resource.email,
                                full_name: resource.full_name,
                                role: resource.role,
                                status: resource.status,
                            }
                        }, status: :ok
                    else
                        render json: { error: "Email o contraseña incorrectos"}, status: :unauthorized 
                    end
                end

                def respond_to_on_destroy
                    render json: { message: "Sesión cerrada correctamente" }, status: :ok
                end

            end
        end
    end
end