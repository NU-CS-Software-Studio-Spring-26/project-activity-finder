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

    assert_equal(
      { from: "profile", return_to: "/users/1", data: { turbo_frame: "_top" } },
      activity_show_link_options(return_to: "/users/1")
    )
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

  test "activity_image uses default asset when no uploads or title match" do
    activity = Activity.create!(
      title: "Neighborhood Board Game Night",
      city: "Seattle",
      category: "Social",
      event_date: Date.today,
      user: @user
    )

    assert_match(/activity_finder_default_thumbnail/, activity_image(activity))
  end
end
