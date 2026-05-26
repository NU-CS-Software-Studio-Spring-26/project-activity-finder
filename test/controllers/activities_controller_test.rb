require "test_helper"

class ActivitiesControllerUnauthenticatedTest < ActionDispatch::IntegrationTest
  test "guest is redirected from activities index" do
    get activities_url
    assert_redirected_to login_path
  end

  test "guest is redirected from root" do
    get root_url
    assert_redirected_to login_path
  end
end

class ActivitiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    # @activity = activities(:one)

    @user = User.create!(
      name: "Test User",
      email: "test@example.com",
      password: "password",
      password_confirmation: "password"
    )

    @activity = Activity.create!(
      title: "Running",
      city: "Seattle",
      category: "Test",
      event_date: Date.today,
      user: @user
    )

    post login_path, params: {
      email: @user.email,
      password: "password"
    }
  end

  test "should get index" do
    get activities_url
    assert_response :success
  end

  test "index filters by search query across title description and category" do
    Activity.create!(
      title: "Weekly Mahjong Meetup",
      city: "Seattle",
      category: "Social",
      description: "Beginners welcome.",
      event_date: Date.today,
      user: @user,
      visibility: "public"
    )

    get activities_url(q: "Mahjong")
    assert_response :success
    assert_select ".activity-card", count: 1
    assert_match(/Weekly Mahjong Meetup/, response.body)
  end

  test "index paginates by per_page and page" do
    4.times do |i|
      Activity.create!(
        title: "Paginated #{i}",
        city: "Seattle",
        category: "Test",
        event_date: Date.today + i.days,
        user: @user
      )
    end

    # 7 activities total (fixtures + setup + 4); per_page 6 → page 2 shows 1 card
    get activities_path(per_page: 6, page: 2)
    assert_response :success
    assert_match(/page 2 of 2/, response.body)
    assert_select ".activity-card", count: 1
  end

  test "index ignores invalid per_page and defaults to 12" do
    get activities_path(per_page: 999)
    assert_response :success
    assert_select "#activities-per-page option[selected]", text: "12"
  end

  test "index json includes activities and pagination" do
    get activities_path(format: :json)
    assert_response :success
    body = JSON.parse(response.body)
    assert body["activities"].is_a?(Array)
    assert_equal 1, body.dig("pagination", "page")
    assert_equal 12, body.dig("pagination", "per_page")
  end

  test "should get new" do
    get new_activity_url
    assert_response :success
  end

  test "should create activity" do
    assert_difference("Activity.count") do
      post activities_url, params: { activity: { category: @activity.category, city: @activity.city, description: @activity.description, event_date: @activity.event_date, location: @activity.location, title: @activity.title } }
    end

    assert_redirected_to activities_path
  end

  test "should show activity" do
    get activity_url(@activity)
    assert_response :success
  end

  test "show generates missing share token for host" do
    @activity.update_column(:share_token, nil)

    get activity_url(@activity)
    assert_response :success
    assert @activity.reload.share_token.present?
    assert_match "/join/", response.body
  end

  test "show page uses same image fallback as index when no uploads" do
    activity = Activity.create!(
      title: "Sunrise Ridge Hike",
      city: "Seattle",
      category: "Hike",
      event_date: Date.today,
      user: @user
    )

    get activity_url(activity)
    assert_response :success
    assert_match %r{hikeoftheweek\.com}, response.body
  end

  test "should get edit from profile" do
    get edit_activity_url(@activity, from: "profile", return_to: user_path(@user))
    assert_response :success
  end

  test "cannot edit without profile source" do
    get edit_activity_url(@activity)
    assert_redirected_to activity_path(@activity)
  end

  test "host show hides management actions when not from profile" do
    get activity_url(@activity)
    assert_response :success
    assert_no_match "Edit Activity", response.body
    assert_no_match "Delete Activity", response.body
  end

  test "host show shows management actions when from profile" do
    get activity_url(@activity, from: "profile", return_to: user_path(@user))
    assert_response :success
    assert_match "Edit Activity", response.body
    assert_match "Delete Activity", response.body
    assert_match "Back to profile", response.body
  end

  test "should update activity from profile" do
    patch activity_url(@activity),
      params: {
        from: "profile",
        return_to: user_path(@user),
        activity: {
          category: @activity.category,
          city: @activity.city,
          description: @activity.description,
          event_date: @activity.event_date,
          location: @activity.location,
          title: @activity.title
        }
      }
    assert_redirected_to user_path(@user)
  end

  test "should destroy activity from profile" do
    assert_difference("Activity.count", -1) do
      delete activity_url(@activity, from: "profile", return_to: user_path(@user))
    end

    assert_redirected_to user_path(@user)
  end

  test "admin can edit another user's activity" do
    admin = User.create!(
      name: "Admin",
      email: "admin@example.com",
      password: "Admin",
      password_confirmation: "Admin",
      admin: true
    )
    other = User.create!(
      name: "Other",
      email: "other2@example.com",
      password: "password",
      password_confirmation: "password"
    )
    foreign = Activity.create!(
      title: "Theirs",
      city: "NYC",
      category: "X",
      event_date: Date.today,
      user: other
    )

    post login_path, params: { email: admin.email, password: "Admin" }
    assert_redirected_to root_path

    get edit_activity_url(foreign)
    assert_response :success
  end

  test "cannot edit another user's activity" do
    other = User.create!(
      name: "Other",
      email: "other@example.com",
      password: "password",
      password_confirmation: "password"
    )
    foreign = Activity.create!(
      title: "Theirs",
      city: "NYC",
      category: "X",
      event_date: Date.today,
      user: other
    )

    get edit_activity_url(foreign)
    assert_redirected_to root_path
    follow_redirect!
    assert_match "Not authorized", response.body
  end

  test "can join and leave someone else's activity" do
    other = User.create!(
      name: "Joiner",
      email: "joiner@example.com",
      password: "password",
      password_confirmation: "password"
    )
    foreign = Activity.create!(
      title: "Theirs",
      city: "NYC",
      category: "X",
      event_date: Date.today,
      user: other
    )

    joiner = User.create!(
      name: "Participant",
      email: "participant@example.com",
      password: "password",
      password_confirmation: "password"
    )

    post login_path, params: { email: joiner.email, password: "password" }

    assert_difference("ActivitySignup.count", 1) do
      post join_activity_url(foreign)
    end
    assert_redirected_to activity_url(foreign)
    follow_redirect!
    assert_match "joined", flash[:notice]

    assert_no_difference("ActivitySignup.count") do
      post join_activity_url(foreign)
    end

    assert_difference("ActivitySignup.count", -1) do
      delete leave_activity_url(foreign)
    end
    assert_redirected_to activity_url(foreign)
  end

  test "cannot join when activity is full" do
    host = User.create!(
      name: "Host",
      email: "fullhost@example.com",
      password: "password",
      password_confirmation: "password"
    )

    filler = User.create!(
      name: "Filler",
      email: "filler@example.com",
      password: "password",
      password_confirmation: "password"
    )

    joiner = User.create!(
      name: "Late Joiner",
      email: "late@example.com",
      password: "password",
      password_confirmation: "password"
    )

    foreign = Activity.create!(
      title: "Tiny event",
      city: "NYC",
      category: "X",
      event_date: Date.today,
      user: host,
      capacity: 1
    )

    ActivitySignup.create!(activity: foreign, user: filler)

    post login_path, params: { email: joiner.email, password: "password" }

    assert_no_difference("ActivitySignup.count") do
      post join_activity_url(foreign)
    end
    assert_redirected_to activity_url(foreign)
    follow_redirect!
    assert_match "full", flash[:alert]
  end

  test "host cannot join their own activity" do
    assert_no_difference("ActivitySignup.count") do
      post join_activity_url(@activity)
    end
    assert_redirected_to activity_url(@activity)
    follow_redirect!
    assert_match "hosting", flash[:alert]
  end
end
