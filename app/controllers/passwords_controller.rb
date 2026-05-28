class PasswordsController < ApplicationController
  before_action :redirect_if_logged_in, only: [ :new, :create ]
  before_action :find_user_by_token, only: [ :edit, :update ]

  def new
  end

  def create
    email = params[:email].to_s.strip.downcase
    user  = User.find_by(email: email)
  
    if user
      token = user.generate_token_for(:password_reset)  # generate fresh token
      UserMailer.password_reset(user, token).deliver_now
    end
  
    redirect_to login_path,
                notice: "If that email is registered, you'll receive password reset instructions shortly."
  end

  def edit
  end

  def update
    if @user.update(password_params)
      redirect_to login_path, notice: "Password updated. Please log in with your new password."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def redirect_if_logged_in
    redirect_to root_path if logged_in?
  end

  def find_user_by_token
    @token = params[:token]
    @user  = User.find_by_token_for(:password_reset, @token)

    unless @user
      redirect_to forgot_password_path,
                  alert: "That password reset link is invalid or has expired. Please try again."
    end
  end

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
