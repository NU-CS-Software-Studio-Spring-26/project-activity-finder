class UserMailer < ApplicationMailer
  def password_reset(user, token)
    @user      = user
    @reset_url = edit_password_reset_url(token)

    mail to: user.email, subject: "Reset your Open Scene password"
  end
end
