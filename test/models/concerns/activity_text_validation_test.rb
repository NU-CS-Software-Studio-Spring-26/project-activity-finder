require "test_helper"

class ActivityTextValidationTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      name: "Test User",
      email: "text-validation@example.com",
      password: "password",
      password_confirmation: "password"
    )
  end

  def build_activity(overrides = {})
    Activity.new({
      title: "Sunset Picnic",
      city: "Seattle",
      category: "Social",
      event_date: Date.today,
      user: @user
    }.merge(overrides))
  end

  test "accepts readable title description and location" do
    activity = build_activity(
      description: "Bring snacks and a blanket.",
      location: "Green Lake Park, 7201 East Green Lake Dr N"
    )

    assert activity.valid?
  end

  test "rejects sql-like title" do
    activity = build_activity(title: "SELECT * FROM database")

    assert_not activity.valid?
    assert_includes activity.errors[:title], "must be a readable activity name"
  end

  test "rejects title without letters" do
    activity = build_activity(title: "12345")

    assert_not activity.valid?
    assert_includes activity.errors[:title], "must include at least one letter"
  end

  test "rejects title that is too short" do
    activity = build_activity(title: "Hi")

    assert_not activity.valid?
    assert activity.errors[:title].any? { |message| message.include?("too short") }
  end

  test "rejects description over max length" do
    activity = build_activity(description: "a" * (Activity::DESCRIPTION_MAX_LENGTH + 1))

    assert_not activity.valid?
    assert activity.errors[:description].any? { |message| message.include?("too long") }
  end

  test "rejects sql-like location" do
    activity = build_activity(location: "DROP TABLE users")

    assert_not activity.valid?
    assert_includes activity.errors[:location], "must be a readable place or address"
  end

  test "strips and squish text fields" do
    activity = build_activity(
      title: "  Board   Game   Night  ",
      location: "  Community   Hall  "
    )

    assert activity.valid?
    assert_equal "Board Game Night", activity.title
    assert_equal "Community Hall", activity.location
  end
end
