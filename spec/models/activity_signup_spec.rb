require "rails_helper"

RSpec.describe ActivitySignup, type: :model do
  let(:host) do
    User.create!(
      name: "Host",
      email: "host@example.com",
      password: "password",
      password_confirmation: "password"
    )
  end

  let(:guest) do
    User.create!(
      name: "Guest",
      email: "guest@example.com",
      password: "password",
      password_confirmation: "password"
    )
  end

  let(:activity) do
    Activity.create!(
      title: "Picnic in the Park",
      city: "Seattle",
      category: "Social & Networking",
      event_date: Date.current,
      user: host
    )
  end

  describe "signing up for an activity" do
    it "allows a user to join once" do
      signup = described_class.new(activity: activity, user: guest)

      expect(signup).to be_valid
      expect(signup.save).to be true
    end

    it "prevents the same user from joining twice" do
      described_class.create!(activity: activity, user: guest)
      duplicate = described_class.new(activity: activity, user: guest)

      expect(duplicate).not_to be_valid
    end

    it "allows different users to join the same activity" do
      other = User.create!(
        name: "Other Guest",
        email: "other@example.com",
        password: "password",
        password_confirmation: "password"
      )

      expect(described_class.create!(activity: activity, user: guest)).to be_persisted
      expect(described_class.create!(activity: activity, user: other)).to be_persisted
      expect(activity.attendee_count).to eq(2)
    end
  end

  describe "capacity tracking" do
    let(:limited_activity) do
      Activity.create!(
        title: "Small Group Hike",
        city: "Seattle",
        category: "Hike",
        event_date: Date.current,
        capacity: 2,
        user: host
      )
    end

    it "reports not at capacity when spots remain" do
      described_class.create!(activity: limited_activity, user: guest)

      expect(limited_activity.attendee_count).to eq(1)
      expect(limited_activity).not_to be_at_capacity
    end

    it "reports at capacity when the limit is reached" do
      second_guest = User.create!(
        name: "Second Guest",
        email: "second@example.com",
        password: "password",
        password_confirmation: "password"
      )

      described_class.create!(activity: limited_activity, user: guest)
      described_class.create!(activity: limited_activity, user: second_guest)

      expect(limited_activity).to be_at_capacity
    end

    it "treats nil capacity as unlimited" do
      described_class.create!(activity: activity, user: guest)

      expect(activity.capacity).to be_nil
      expect(activity).not_to be_at_capacity
    end
  end
end
