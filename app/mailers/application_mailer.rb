class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "Activity Finder <noreply@activityfinder.example.com>")
  layout "mailer"
end
