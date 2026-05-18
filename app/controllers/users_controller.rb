class UsersController < ApplicationController
  include ActivityListPagination

  before_action :set_user, only: [ :show, :edit, :update, :destroy ]
  before_action :require_login, except: [ :new, :create ]
  before_action :authorize_user!, only: [ :edit, :update, :destroy ]

  def authorize_user!
    return if current_user.admin?
    return if @user == current_user

    redirect_to root_path, alert: "Not authorized"
  end

  def show
    @profile_tab = %w[created joined].include?(params[:tab]) ? params[:tab] : "created"

    hosted_scope = @user.activities.order(event_date: :asc)
    hosted_result = paginate_activity_scope(hosted_scope, page_param: :created_page)
    @hosted_activities = hosted_result[:records]
    @created_pagination = hosted_result[:pagination]

    joined_scope = @user.joined_activities.includes(:user).order(event_date: :asc)
    joined_result = paginate_activity_scope(joined_scope, page_param: :joined_page)
    @joined_activities = joined_result[:records]
    @joined_pagination = joined_result[:pagination]
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(signup_params)

    if @user.save
      reset_session
      session[:user_id] = @user.id
      redirect_to root_path, notice: "Account created successfully!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    @user.avatar.purge if params.dig(:user, :remove_avatar) == "1"

    if @user.update(profile_params)
      redirect_to @user, notice: "Profile updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @user.destroy
    redirect_to root_path, notice: "User deleted successfully."
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def signup_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end

  def profile_params
    params.require(:user).permit(:name, :password, :password_confirmation, :avatar)
  end
end
