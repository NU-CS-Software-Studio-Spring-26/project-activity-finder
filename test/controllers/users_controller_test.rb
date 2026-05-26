require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @alice = User.create!(
      name: "Alice",
      email: "alice@example.com",
      password: "password",
      password_confirmation: "password"
    )
    @bob = User.create!(
      name: "Bob",
      email: "bob@example.com",
      password: "password",
      password_confirmation: "password"
    )
    post login_path, params: { email: @alice.email, password: "password" }
  end

  test "logged-in user can view another user's profile" do
    get user_url(@bob)
    assert_response :success
    assert_match @bob.name, response.body
  end

  test "profile paginates created activities" do
    7.times do |i|
      Activity.create!(
        title: "Alice activity #{i}",
        city: "Seattle",
        category: "Test",
        event_date: Date.today + i.days,
        user: @alice
      )
    end

    get user_url(@alice, per_page: 6, created_page: 2, tab: "created")
    assert_response :success
    assert_match(/page 2 of 2/, response.body)
    assert_select "#profile-panel-created .activity-card", count: 1
  end

  test "profile paginates joined activities on joined tab" do
    7.times do |i|
      activity = Activity.create!(
        title: "Joinable #{i}",
        city: "Seattle",
        category: "Test",
        event_date: Date.today + i.days,
        user: @bob
      )
      activity.activity_signups.create!(user: @alice)
    end

    get user_url(@alice, per_page: 6, joined_page: 2, tab: "joined")
    assert_response :success
    assert_match(/page 2 of 2/, response.body)
    assert_select "#profile-panel-joined .activity-card", count: 1
  end

  test "cannot edit another user" do
    get edit_user_url(@bob)
    assert_redirected_to root_path
    follow_redirect!
    assert_match "Not authorized", response.body
  end

  test "cannot update another user" do
    patch user_url(@bob), params: {
      user: { name: "Hacked", email: @bob.email, password: "", password_confirmation: "" }
    }
    assert_redirected_to root_path
    @bob.reload
    assert_equal "Bob", @bob.name
  end

  test "cannot destroy another user" do
    assert_no_difference("User.count") do
      delete user_url(@bob)
    end
    assert_redirected_to root_path
  end

  test "admin profile shows all activities with search and without create button" do
    admin = User.create!(
      name: "Admin",
      email: "admin-profile@example.com",
      password: "AdminPass1",
      password_confirmation: "AdminPass1",
      admin: true
    )
    post login_path, params: { email: admin.email, password: "AdminPass1" }

    alice_activity = Activity.create!(
      title: "Alice hike",
      city: "Seattle",
      category: "Hike",
      event_date: Date.today,
      user: @alice
    )
    bob_activity = Activity.create!(
      title: "Bob trivia",
      city: "Portland",
      category: "Trivia Night",
      event_date: Date.today + 1.day,
      user: @bob
    )

    get user_url(admin)
    assert_response :success
    assert_select "h2.profile-activities-heading", text: "All activities"
    assert_select ".profile-activities-tab", count: 0
    assert_select ".profile-create-activity-btn", count: 0
    assert_select "#profile-panel-all .activity-card", count: 2
    assert_select "button", text: "Delete", count: 2

    get user_url(admin, q: "trivia")
    assert_response :success
    assert_select "#profile-panel-all .activity-card", count: 1
    assert_match bob_activity.title, response.body
    assert_no_match alice_activity.title, response.body

    get user_url(admin, city: "Seattle")
    assert_response :success
    assert_select "#profile-panel-all .activity-card", count: 1
    assert_match alice_activity.title, response.body
  end

  test "admin profile paginates all activities" do
    admin = User.create!(
      name: "Admin",
      email: "admin-paginate@example.com",
      password: "AdminPass1",
      password_confirmation: "AdminPass1",
      admin: true
    )
    post login_path, params: { email: admin.email, password: "AdminPass1" }

    7.times do |i|
      Activity.create!(
        title: "Listed #{i}",
        city: "Seattle",
        category: "Test",
        event_date: Date.today + i.days,
        user: @alice
      )
    end

    get user_url(admin, per_page: 6, page: 2)
    assert_response :success
    assert_match(/page 2 of 2/, response.body)
    assert_select "#profile-panel-all .activity-card", count: 1
  end

  test "admin can delete any activity from profile" do
    admin = User.create!(
      name: "Admin",
      email: "admin-delete@example.com",
      password: "AdminPass1",
      password_confirmation: "AdminPass1",
      admin: true
    )
    post login_path, params: { email: admin.email, password: "AdminPass1" }

    activity = Activity.create!(
      title: "To remove",
      city: "Seattle",
      category: "Test",
      event_date: Date.today,
      user: @bob
    )

    assert_difference("Activity.count", -1) do
      delete activity_url(activity),
        params: { from: "profile", return_to: user_path(admin) }
    end
    assert_redirected_to user_path(admin)
  end

  test "admin can edit and destroy another user" do
    admin = User.create!(
      name: "Admin",
      email: "admin-user@example.com",
      password: "Admin",
      password_confirmation: "Admin",
      admin: true
    )
    post login_path, params: { email: admin.email, password: "Admin" }
    assert_redirected_to root_path

    get edit_user_url(@bob)
    assert_response :success

    assert_difference("User.count", -1) do
      delete user_url(@bob)
    end
    assert_redirected_to root_path
  end
end
