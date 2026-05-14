class SessionsController < ApplicationController
  before_action :redirect_if_logged_in, only: [ :new ]

  def new
  end

  def create
    email = params[:email].to_s.strip.downcase
    user = User.find_by(email: email)

    if user&.authenticate(params[:password])
      reset_session
      session[:user_id] = user.id
      redirect_to root_path, notice: "Logged in successfully"
    else
      flash.now[:alert] = "Invalid email or password"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to login_path, notice: "Logged out successfully"
  end

  private

  def redirect_if_logged_in
    redirect_to root_path if logged_in?
  end
end
