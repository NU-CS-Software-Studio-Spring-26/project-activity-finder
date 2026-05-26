class SessionsController < ApplicationController
  before_action :redirect_if_logged_in, only: [ :new ]
  skip_before_action :verify_authenticity_token, only: [ :omniauth ]

  def new
  end

  def create
    email = params[:email].to_s.strip.downcase
    user = User.find_by(email: email)

    if user&.authenticate(params[:password])
      return_to = session[:return_to]
      reset_session
      session[:user_id] = user.id
      redirect_to return_to.presence || root_path, notice: "Logged in successfully"
    else
      flash.now[:alert] = "Invalid email or password"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to login_path, notice: "Logged out successfully"
  end

  def omniauth
    auth = request.env["omniauth.auth"]
    unless auth
      redirect_to login_path, alert: "Google sign-in failed."
      return
    end

    user, sign_in_kind = User.from_omniauth(auth)
    return_to = session[:return_to]
    reset_session
    session[:user_id] = user.id
    notice =
      case sign_in_kind
      when :new
        "Account successfully created, #{user.name}."
      when :returning
        "Welcome back, #{user.name}."
      else
        "Signed in with Google."
      end
    redirect_to return_to.presence || root_path, notice: notice
  rescue ArgumentError, ActiveRecord::RecordInvalid => e
    message =
      if e.is_a?(ActiveRecord::RecordInvalid)
        e.record.errors.full_messages.to_sentence
      else
        e.message
      end
    redirect_to login_path, alert: message.presence || "Google sign-in failed."
  end

  def omniauth_failure
    redirect_to login_path,
                  alert: params[:message].presence || "Google sign-in was cancelled or failed."
  end

  private

  def redirect_if_logged_in
    redirect_to root_path if logged_in?
  end
end
