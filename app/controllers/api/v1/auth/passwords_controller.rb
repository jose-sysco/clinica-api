module Api
  module V1
    module Auth
      class PasswordsController < ApplicationController
        skip_before_action :authenticate_user!
        skip_before_action :set_tenant

        def forgot
          organization = Organization.find_by(slug: params[:slug], status: :active)

          if organization.nil?
            render json: { error: 'Organización no encontrada' }, status: :not_found
            return
          end

          ActsAsTenant.with_tenant(organization) do
            user = User.find_by(email: params[:email])

            if user
              # Generamos el token manualmente sin usar el mailer de Devise
              raw_token, hashed_token = Devise.token_generator.generate(User, :reset_password_token)

              user.update!(
                reset_password_token:    hashed_token,
                reset_password_sent_at:  Time.now.utc
              )

              # Enviamos nuestro propio mailer
              PasswordMailer.reset_password(user, raw_token, organization).deliver_now
            end
          end

          render json: {
            message: 'Si el email existe recibirás instrucciones para restablecer tu contraseña'
          }, status: :ok
        end

        def reset
          organization = Organization.find_by(slug: params[:slug], status: :active)

          if organization.nil?
            render json: { error: 'Organización no encontrada' }, status: :not_found
            return
          end

          ActsAsTenant.with_tenant(organization) do
            user = User.reset_password_by_token(
              reset_password_token:  params[:token],
              password:              params[:password],
              password_confirmation: params[:password_confirmation]
            )

            if user.errors.empty?
              render json: { message: 'Contraseña restablecida correctamente' }, status: :ok
            else
              render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
            end
          end
        end
      end
    end
  end
end