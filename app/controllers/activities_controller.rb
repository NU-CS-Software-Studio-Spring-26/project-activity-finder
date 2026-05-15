class ActivitiesController < ApplicationController
  ACTIVITIES_PER_PAGE_CHOICES = [ 6, 12, 24, 48 ].freeze

  before_action :require_login
  before_action :set_activity, only: %i[ show edit update destroy join leave ]
  before_action :authorize_activity!, only: %i[ edit update destroy ]

  def authorize_activity!
    return if current_user.admin?
    redirect_to root_path, alert: "Not authorized" unless @activity.user == current_user
  end

  # GET /activities or /activities.json
  def index
    per_page = activities_per_page
    @city_query = params[:city].to_s.strip

    base_scope = Activity.order(event_date: :asc)
    if @city_query.present?
      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(@city_query)}%"
      base_scope = base_scope.where("city ILIKE ?", pattern)
    end

    total = base_scope.count
    total_pages = total.zero? ? 1 : (total + per_page - 1) / per_page
    page = activities_page_param(total_pages)

    @activities = base_scope.offset((page - 1) * per_page).limit(per_page)
    @pagination = {
      page: page,
      per_page: per_page,
      total: total,
      total_pages: total_pages,
      first_number: total.zero? ? 0 : (page - 1) * per_page + 1,
      last_number: (page - 1) * per_page + @activities.size
    }

    activity_ids = @activities.map(&:id)
    @signup_counts = ActivitySignup.where(activity_id: activity_ids).group(:activity_id).count
    @joined_activity_ids = ActivitySignup.where(user: current_user, activity_id: activity_ids).pluck(:activity_id).to_set
  end

  # GET /activities/1 or /activities/1.json
  def show
    @joined = @activity.attendees.exists?(current_user.id)
    @attendees = @activity.attendees.order(:name)
    @signup_count = @activity.activity_signups.count
    @full = @activity.capacity.present? && @signup_count >= @activity.capacity
  end

  # POST /activities/1/join
  def join
    if @activity.user_id == current_user.id
      redirect_to @activity, alert: "You’re hosting this activity."
      return
    end

    signup = @activity.activity_signups.find_or_initialize_by(user: current_user)

    if signup.persisted?
      redirect_to @activity, notice: "You’re already signed up."
      return
    end

    if @activity.capacity.present? && @activity.activity_signups.count >= @activity.capacity
      redirect_to @activity, alert: "This activity is full."
      return
    end

    begin
      if signup.save
        redirect_to @activity, notice: "You joined this activity."
      else
        redirect_to @activity, alert: signup.errors.full_messages.to_sentence
      end
    rescue ActiveRecord::RecordNotUnique
      redirect_to @activity, alert: "This activity is full."
    end
  end

  # DELETE /activities/1/leave
  def leave
    removed = @activity.activity_signups.where(user: current_user).destroy_all

    if removed.any?
      redirect_to @activity, notice: "You left this activity."
    else
      redirect_to @activity, alert: "You weren’t signed up for this activity."
    end
  end

  # GET /activities/new
  def new
    @activity = Activity.new
  end

  # GET /activities/1/edit
  def edit
  end

  # POST /activities or /activities.json
  def create
    @activity = current_user.activities.build(activity_params)

    if @activity.save
      attach_new_images
      normalize_image_positions
      redirect_to activities_path, notice: "Activity created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /activities/1 or /activities/1.json
  def update
    if @activity.update(activity_params)
      purge_selected_images
      attach_new_images
      update_image_order
      normalize_image_positions
      redirect_to activities_path, notice: "Activity updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /activities/1 or /activities/1.json
  def destroy
    @activity.destroy!

    respond_to do |format|
      format.html { redirect_to activities_path, notice: "Activity was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    def activities_per_page
      n = params[:per_page].to_i
      ACTIVITIES_PER_PAGE_CHOICES.include?(n) ? n : 12
    end

    def activities_page_param(total_pages)
      p = params[:page].to_i
      p = 1 if p < 1
      [ p, total_pages ].min
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_activity
      @activity = Activity.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def activity_params
      params.expect(activity: [
          :title,
          :description,
          :location,
          :city,
          :category,
          :event_date,
          :capacity
        ])
    end

    def attach_new_images
      uploaded_images = params.dig(:activity, :images)
      return if uploaded_images.blank?
      remaining_slots = 10 - @activity.images.attachments.count
      images_to_attach = uploaded_images.first(remaining_slots)
      @activity.images.attach(images_to_attach)
    end

    def purge_selected_images
      ids = params.dig(:activity, :remove_image_ids)&.reject(&:blank?) || []
      ids.each do |id|
        attachment = @activity.images.attachments.find_by(id: id)
        attachment&.purge
      end
    end

    def update_image_order
      ordered_ids = params.dig(:activity, :image_order)&.reject(&:blank?) || []
      ordered_ids.each_with_index do |id, index|
        attachment = @activity.images.attachments.find_by(id: id)
        attachment&.update(position: index + 1)
      end
    end

    def normalize_image_positions
      @activity.images.attachments.order(:position, :created_at).each_with_index do |attachment, index|
        attachment.update(position: index + 1)
      end
    end
end
