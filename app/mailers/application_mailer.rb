class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "Activity Finder <openscene8@gmail.com>")
  layout "mailer"
end
