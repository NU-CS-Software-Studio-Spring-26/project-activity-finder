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
