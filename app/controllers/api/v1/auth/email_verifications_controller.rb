module Api
  module V1
    module Auth
      class EmailVerificationsController < ApplicationController
        skip_before_action :authenticate_user!
        skip_before_action :set_tenant

        # POST /api/v1/auth/verify_email
        # Body: { token: "..." }
        def verify
          user = ActsAsTenant.without_tenant do
            User.find_by(email_verification_token: params[:token])
          end

          if user.nil?
            render json: {
              error: "Token inválido o ya fue utilizado.",
              code:  "invalid_token"
            }, status: :unprocessable_entity
            return
          end

          user.update!(
            email_verified_at:        Time.current,
            email_verification_token: nil
          )

          render json: { message: "Correo verificado exitosamente. Ya puedes iniciar sesión." }, status: :ok
        end

        # POST /api/v1/auth/resend_verification
        # Body: { email: "...", organization_slug: "..." }
        def resend
          organization = ActsAsTenant.without_tenant do
            Organization.find_by(slug: params[:organization_slug])
          end

          if organization
            user = User.where(organization: organization).find_by(email: params[:email]&.downcase&.strip)

            if user && !user.email_verified?
              user.update!(email_verification_token: SecureRandom.urlsafe_base64(32))
              EmailVerificationJob.perform_later(user.id)
            end
          end

          # Siempre 200 para no revelar si el email existe
          render json: { message: "Si el correo existe y no está verificado, recibirás un nuevo enlace." }, status: :ok
        end
      end
    end
  end
end
