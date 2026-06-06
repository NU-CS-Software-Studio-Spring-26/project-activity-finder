class ActivitiesController < ApplicationController
  include ActivityListPagination
  include ActivityNavigation

  before_action :require_login
  before_action :set_activity, only: %i[ show edit update destroy join leave export_pdf export_ics ]
  before_action :check_activity_access!, only: %i[ show join leave export_ics ]
  before_action :authorize_activity!, only: %i[ edit update destroy ]
  before_action :authorize_pdf_export!, only: :export_pdf
  before_action :require_profile_management_context!, only: %i[ edit update destroy ]

  def authorize_activity!
    return if current_user.admin?
    redirect_to root_path, alert: "Not authorized" unless @activity.user == current_user
  end

  # GET /activities or /activities.json
  def index
    @city_query     = params[:city].to_s.strip
    @title_query    = params[:q].to_s.strip
    @category_query = params[:category].to_s.strip

    base_scope = Activity.publicly_visible.order(event_date: :asc)
    if @city_query.present?
      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(@city_query)}%"
      base_scope = base_scope.where("city ILIKE ?", pattern)
    end

    # Layout is an explicit, URL-persisted choice so it stays consistent across
    # navigation (clicking a card and coming back keeps the same layout).
    #   view=grouped → Airbnb-style horizontal rows grouped by category
    #   view=list    → flat, paginated grid of every matching activity
    # Some actions only make sense as a flat list, so they force list mode
    # regardless of the toggle: a text search, a single-category filter,
    # pagination, or a JSON request.
    requested_view  = params[:view].to_s
    inherently_list = @title_query.present? || @category_query.present? ||
                      params[:page].present? || params[:per_page].present? ||
                      request.format.json?
    @browsing_mode  = !inherently_list && requested_view != "list"
    @view_mode      = @browsing_mode ? "grouped" : "list"

    if @browsing_mode
      all = base_scope.limit(300).to_a
      ordered_cats = Activity::CATEGORIES + (all.map(&:category).uniq - Activity::CATEGORIES)
      @activities_by_category = ordered_cats.filter_map do |cat|
        acts = all.select { |a| a.category == cat }.first(12)
        [ cat, acts ] unless acts.empty?
      end.to_h

      all_ids = @activities_by_category.values.flatten.map(&:id)
      @signup_counts       = ActivitySignup.where(activity_id: all_ids).group(:activity_id).count
      @joined_activity_ids = ActivitySignup.where(user: current_user, activity_id: all_ids).pluck(:activity_id).to_set
      @pagination = nil
    else
      if @title_query.present?
        pattern = "%#{ActiveRecord::Base.sanitize_sql_like(@title_query)}%"
        base_scope = base_scope.where(
          "title ILIKE :q OR COALESCE(description, '') ILIKE :q OR COALESCE(category, '') ILIKE :q",
          q: pattern
        )
      end
      base_scope = base_scope.where(category: @category_query) if @category_query.present?

      result = paginate_activity_scope(base_scope, page_param: :page)
      @activities = result[:records]
      @pagination = result[:pagination]

      activity_ids = @activities.map(&:id)
      @signup_counts       = ActivitySignup.where(activity_id: activity_ids).group(:activity_id).count
      @joined_activity_ids = ActivitySignup.where(user: current_user, activity_id: activity_ids).pluck(:activity_id).to_set
    end
  end

  # GET /activities/1 or /activities/1.json
  def show
    @from_profile = from_profile?
    @return_to = activity_list_return_path
    @show_manage_actions = show_activity_management?
    @joined = @activity.attendees.exists?(current_user.id)
    @attendees = @activity.attendees.order(:name)
    @signup_count = @activity.activity_signups.count
    @full = @activity.capacity.present? && @signup_count >= @activity.capacity
    @map_coordinates = geocode_activity_location if helpers.activity_location_map_showable?(@activity)
    if @activity.user == current_user
      token = ensure_share_token!(@activity)
      @share_url = join_activity_via_token_url(token: token)
    end
  end

  # GET /join/:token
  def join_via_token
    @activity = Activity.find_by(share_token: params[:token])

    unless @activity
      redirect_to root_path, alert: "Invalid or expired invitation link."
      return
    end

    grant_token_access(@activity)

    if @activity.public?
      redirect_to @activity, notice: "Welcome! You can join this activity below."
    else
      redirect_to @activity, notice: "You've been granted access to this private activity. Join below!"
    end
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

  # GET /activities/1/export_pdf
  def export_pdf
    pdf_data = ActivityPdfExporter.new(@activity).render
    send_data pdf_data,
              filename: "activity-#{@activity.id}-report.pdf",
              type: "application/pdf",
              disposition: "attachment"
  end

  # GET /activities/1/export_ics
  def export_ics
    send_data ActivityCalendarExporter.new(@activity).render,
              filename: "activity-#{@activity.id}.ics",
              type: "text/calendar; charset=utf-8",
              disposition: "attachment"
  end

  # GET /activities/new
  def new
    @activity = Activity.new(prefill_params)
  end

  # GET /activities/1/edit
  def edit
    @from_profile = from_profile?
    @return_to = activity_list_return_path
  end

  # POST /activities or /activities.json
  def create
    @activity = current_user.activities.build(activity_params)

    if bot_submission?
      flash.now[:alert] = "We couldn't verify your submission. Please try again."
      render :new, status: :unprocessable_entity
      return
    end

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
      redirect_to activity_list_return_path, notice: "Activity updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /activities/1 or /activities/1.json
  def destroy
    @activity.destroy!

    respond_to do |format|
      format.html { redirect_to activity_list_return_path, notice: "Activity was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
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
          :capacity,
          :visibility
        ])
    end

    # Optional, non-destructive prefill for GET /activities/new (e.g. from the
    # Activity Advisor). Only whitelisted fields are read; the user still reviews
    # and submits the form, so validation happens normally on create.
    def prefill_params
      return {} unless params[:activity].present?

      params.fetch(:activity, {}).permit(
        :title, :description, :location, :city, :category, :event_date, :capacity
      )
    end

    def check_activity_access!
      return unless @activity.private?
      return if @activity.user == current_user
      return if @activity.attendees.exists?(current_user.id)
      return if token_access_granted?(@activity)

      redirect_to root_path, alert: "This activity is private. You need an invitation link to view it."
    end

    def grant_token_access(activity)
      session[:activity_access_tokens] ||= {}
      session[:activity_access_tokens][activity.id.to_s] = activity.share_token
    end

    def token_access_granted?(activity)
      stored = session.dig(:activity_access_tokens, activity.id.to_s)
      stored.present? && stored == activity.share_token
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

    def geocode_activity_location
      LocationGeocoder.coordinates(@activity.location, city: @activity.city)
    end

    def authorize_pdf_export!
      return if current_user.admin?
      return if @activity.user == current_user
      return if @activity.attendees.exists?(current_user.id)

      redirect_to @activity, alert: "Only the host or joined attendees can export this activity report."
    end

    def ensure_share_token!(activity)
      return activity.share_token if activity.share_token.present?

      token = loop do
        candidate = SecureRandom.urlsafe_base64(16)
        break candidate unless Activity.exists?(share_token: candidate)
      end

      activity.update_column(:share_token, token)
      token
    end
end
