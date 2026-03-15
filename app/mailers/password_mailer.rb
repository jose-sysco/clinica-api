class PasswordMailer < ApplicationMailer
  def reset_password(user, token, organization)
    @user         = user
    @token        = token
    @organization = organization
    @reset_url    = "#{ENV.fetch('FRONTEND_URL', 'http://localhost:3000')}/reset-password?token=#{token}&slug=#{organization.slug}"

    mail(
      to:      user.email,
      subject: "Restablecer contraseña — #{organization.name}"
    )
  end
end