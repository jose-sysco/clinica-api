class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "no-reply@clinicaportal.com")
  layout "mailer"
end
