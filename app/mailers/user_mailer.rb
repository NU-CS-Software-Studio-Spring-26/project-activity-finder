class UserMailer < ApplicationMailer
  def password_reset(user, token)
    @user      = user
    @reset_url = edit_password_reset_url(token)

    # #region agent log
    begin; require "fileutils"; p="/Users/gracehe/project-avtivity-finder/.cursor/debug-27e15a.log"; FileUtils.mkdir_p(File.dirname(p)); File.open(p,"a"){|f|f.puts({sessionId:"27e15a",hypothesisId:"H-C",location:"user_mailer.rb",message:"reset_url",data:{url:@reset_url.to_s},timestamp:Time.now.to_i*1000}.to_json)}; rescue; end
    # #endregion
    mail to: user.email, subject: "Reset your Open Scene password"
  end
end
