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

  test "is invalid when title exceeds maximum length" do
    activity = Activity.new(
      title: "a" * (Activity::TITLE_MAX_LENGTH + 1),
      city: "Seattle",
      category: "Test",
      event_date: Date.today,
      user: @user
    )

    assert_not activity.valid?
    assert activity.errors.of_kind?(:title, :too_long)
  end

  test "is invalid when city exceeds maximum length" do
    activity = Activity.new(
      title: "City Walk",
      city: "a" * (Activity::CITY_MAX_LENGTH + 1),
      category: "Test",
      event_date: Date.today,
      user: @user
    )

    assert_not activity.valid?
    assert activity.errors.of_kind?(:city, :too_long)
  end

  test "is invalid when description exceeds maximum length" do
    activity = Activity.new(
      title: "City Walk",
      city: "Seattle",
      category: "Test",
      event_date: Date.today,
      description: "a" * (Activity::DESCRIPTION_MAX_LENGTH + 1),
      user: @user
    )

    assert_not activity.valid?
    assert activity.errors.of_kind?(:description, :too_long)
  end
end
