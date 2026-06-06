require "test_helper"

class ActivitiesHelperTest < ActionView::TestCase
  include ActivitiesHelper

  setup do
    @user = User.create!(
      name: "Test User",
      email: "helper-test@example.com",
      password: "password",
      password_confirmation: "password"
    )
  end

  test "activity_show_link_options targets top frame for full-page navigation" do
    assert_equal({ data: { turbo_frame: "_top" } }, activity_show_link_options)
  end

  test "activity_show_path encodes list return_to as a query param" do
    activity = Activity.new(id: 42)
    href = activity_show_path(activity, list_return_to: "/activities?page=3&per_page=12")
    return_to = Rack::Utils.parse_query(URI.parse(href).query)["return_to"]

    assert_equal "/activities?page=3&per_page=12", return_to
  end

  test "activity_index_return_path includes page when beyond first page" do
    pagination = { page: 3, per_page: 12 }

    controller.request.path = "/"
    assert_equal "/?page=3&per_page=12", activity_index_return_path(pagination: pagination)

    controller.request.path = "/activities"
    assert_equal "/activities?page=3&per_page=12", activity_index_return_path(pagination: pagination)
  end

  test "activity_link_params adds profile context" do
    assert_equal({ from: "profile", return_to: "/users/1" }, activity_link_params(return_to: "/users/1"))
  end

  test "activity_image uses title-based external fallback when no uploads" do
    activity = Activity.create!(
      title: "Sunrise Ridge Hike",
      city: "Seattle",
      category: "Hike",
      event_date: Date.today,
      user: @user
    )

    assert_match %r{hikeoftheweek\.com}, activity_image(activity)
  end

  test "activity_location_map_showable? is false for blank or virtual locations" do
    online_activity = Activity.new(location: "Online")
    virtual_activity = Activity.new(location: "Virtual")
    blank_activity = Activity.new(location: "")

    assert_not activity_location_map_showable?(online_activity)
    assert_not activity_location_map_showable?(virtual_activity)
    assert_not activity_location_map_showable?(blank_activity)
  end

  test "activity_location_map_showable? is true for physical addresses" do
    activity = Activity.new(location: "123 Main St")

    assert activity_location_map_showable?(activity)
  end

  test "activity_image returns a category SVG placeholder when no uploads or title match" do
    activity = Activity.create!(
      title: "Neighborhood Board Game Night",
      city: "Seattle",
      category: "Social & Networking",
      event_date: Date.today,
      user: @user
    )

    img = activity_image(activity)
    assert img.start_with?("data:image/svg+xml;base64,"), "expected an SVG data URI, got: #{img[0..60]}"
    decoded = Base64.strict_decode64(img.delete_prefix("data:image/svg+xml;base64,"))
    assert_includes decoded, "Social &amp; Networking"
  end
end
