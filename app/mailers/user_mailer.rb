class UserMailer < ApplicationMailer
  def verification_instructions(user)
    @user         = user
    @organization = user.organization
    @verification_url = "#{ENV.fetch('FRONTEND_URL', 'http://localhost:3000').chomp('/')}/verify-email?token=#{user.email_verification_token}"

    mail(
      to:      @user.email,
      subject: "Verifica tu cuenta - #{@organization.name}"
    )
  end
end
