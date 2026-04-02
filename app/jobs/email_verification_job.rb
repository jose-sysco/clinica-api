class EmailVerificationJob < ApplicationJob
  queue_as :mailers

  def perform(user_id)
    user = ActsAsTenant.without_tenant { User.find(user_id) }
    return if user.email_verified?

    ActsAsTenant.with_tenant(user.organization) do
      UserMailer.verification_instructions(user).deliver_now
    end
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn "EmailVerificationJob: User #{user_id} not found"
  rescue => e
    Rails.logger.error "EmailVerificationJob error: #{e.message}"
    raise
  end
end
