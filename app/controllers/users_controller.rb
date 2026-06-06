class UsersController < ApplicationController
  include ActivityListPagination

  before_action :set_user, only: [ :show, :edit, :update, :destroy ]
  before_action :require_login, except: [ :new, :create, :check_email ]
  before_action :authorize_user!, only: [ :edit, :update, :destroy ]

  def authorize_user!
    return if current_user.admin?
    return if @user == current_user

    redirect_to root_path, alert: "Not authorized"
  end

  def show
    if admin_profile_view?
      load_admin_profile_activities
    else
      load_regular_profile_activities
    end
  end

  def new
    @user = User.new
  end

  def check_email
    email = params[:email].to_s.strip.downcase

    if email.blank? || !email.match?(URI::MailTo::EMAIL_REGEXP)
      render json: { available: false, error: "invalid" }
      return
    end

    available = !User.exists?(email: email)
    render json: { available: available }
  end

  def create
    @user = User.new(signup_params)

    if bot_submission?
      flash.now[:alert] = "We couldn't verify your submission. Please try again."
      render :new, status: :unprocessable_entity
      return
    end

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

  def admin_profile_view?
    @user.admin? && @user == current_user
  end

  def load_admin_profile_activities
    @admin_profile = true
    @search_query = params[:q].to_s.strip
    @city_query = params[:city].to_s.strip

    scope = Activity.includes(:user).order(event_date: :asc)
    if @search_query.present?
      title_pattern = "%#{ActiveRecord::Base.sanitize_sql_like(@search_query)}%"
      scope = scope.where("title ILIKE ?", title_pattern)
    end
    if @city_query.present?
      city_pattern = "%#{ActiveRecord::Base.sanitize_sql_like(@city_query)}%"
      scope = scope.where("city ILIKE ?", city_pattern)
    end

    result = paginate_activity_scope(scope, page_param: :page)
    @all_activities = result[:records]
    @activities_pagination = result[:pagination]
  end

  def load_regular_profile_activities
    @admin_profile = false
    @profile_tab = %w[created joined].include?(params[:tab]) ? params[:tab] : "created"

    viewing_own_profile = current_user == @user

    hosted_base = viewing_own_profile ? @user.activities : @user.activities.publicly_visible
    hosted_result = paginate_activity_scope(hosted_base.order(event_date: :asc), page_param: :created_page)
    @hosted_activities = hosted_result[:records]
    @created_pagination = hosted_result[:pagination]

    joined_base = viewing_own_profile ? @user.joined_activities : @user.joined_activities.publicly_visible
    joined_result = paginate_activity_scope(joined_base.includes(:user).order(event_date: :asc), page_param: :joined_page)
    @joined_activities = joined_result[:records]
    @joined_pagination = joined_result[:pagination]
  end
end
