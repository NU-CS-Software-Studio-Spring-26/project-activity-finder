require "test_helper"

class ActivityTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      name: "Test User",
      email: "user@example.com",
      password: "password",
      password_confirmation: "password"
    )
  end

  test "is valid with required fields" do
    activity = Activity.new(title: "City Walk", city: "Seattle", category: "Test", event_date: Date.today, user: @user)

    assert activity.valid?
  end

  test "is invalid without title" do
    activity = Activity.new(city: "Seattle", event_date: Date.today)

    assert_not activity.valid?
    assert_includes activity.errors[:title], "can't be blank"
  end

  test "is invalid without city" do
    activity = Activity.new(title: "City Walk", event_date: Date.today)

    assert_not activity.valid?
    assert_includes activity.errors[:city], "can't be blank"
  end

  test "preset_category? is true for listed categories" do
    activity = Activity.new(category: "Hike")

    assert activity.preset_category?
  end

  test "preset_category? is false for custom categories" do
    activity = Activity.new(category: "Book Club")

    assert_not activity.preset_category?
  end

  test "strips whitespace from category" do
    activity = Activity.new(
      title: "City Walk",
      city: "Seattle",
      category: "  Hike  ",
      event_date: Date.today,
      user: @user
    )

    assert activity.valid?
    assert_equal "Hike", activity.category
  end
end
