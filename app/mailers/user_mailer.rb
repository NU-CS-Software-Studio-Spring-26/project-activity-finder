class UserMailer < ApplicationMailer
  def password_reset(user, token)
    @user      = user
    @reset_url = edit_password_reset_url(token)

    # #region agent log
    File.open("/Users/gracehe/project-avtivity-finder/.cursor/debug-27e15a.log","a"){|f|f.puts({sessionId:"27e15a",hypothesisId:"H-A",location:"user_mailer.rb:4",message:"reset_url generated",data:{reset_url:@reset_url.to_s.sub(/\/[^\/]+$/, "/<token>")},timestamp:Time.now.to_i*1000}.to_json)}
    # #endregion

    mail to: user.email, subject: "Reset your Open Scene password"
  end
end
