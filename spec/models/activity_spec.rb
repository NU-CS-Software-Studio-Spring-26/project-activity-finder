require "rails_helper"

RSpec.describe Activity, type: :model do
  let(:user) do
    User.create!(
      name: "Test User",
      email: "owner@example.com",
      password: "password",
      password_confirmation: "password"
    )
  end

  # Minimal set of attributes that produce a valid Activity. Individual examples
  # override one key at a time to isolate the validation under test.
  def build_activity(overrides = {})
    Activity.new({
      title: "City Walk",
      city: "Seattle",
      category: "Hike",
      event_date: Date.current,
      user: user
    }.merge(overrides))
  end

  describe "a fully populated activity" do
    it "is valid" do
      expect(build_activity).to be_valid
    end
  end

  describe "city" do
    it "is required" do
      activity = build_activity(city: nil)

      expect(activity).not_to be_valid
      expect(activity.errors[:city]).to include("can't be blank")
    end

    it "must be one of the supported cities" do
      activity = build_activity(city: "Atlantis")

      expect(activity).not_to be_valid
      expect(activity.errors[:city]).to include("must be a supported city")
    end

    it "accepts any city listed in ALLOWED_CITIES" do
      Activity::ALLOWED_CITIES.each do |city|
        expect(build_activity(city: city)).to be_valid
      end
    end

    it "strips surrounding whitespace before validating" do
      activity = build_activity(city: "  Seattle  ")

      expect(activity).to be_valid
      expect(activity.city).to eq("Seattle")
    end
  end

  describe "category" do
    it "is required" do
      activity = build_activity(category: nil)

      expect(activity).not_to be_valid
      expect(activity.errors[:category]).to include("can't be blank")
    end

    it "accepts a custom (non-preset) category" do
      expect(build_activity(category: "Book Club")).to be_valid
    end

    it "strips surrounding whitespace before validating" do
      activity = build_activity(category: "  Hike  ")

      expect(activity).to be_valid
      expect(activity.category).to eq("Hike")
    end
  end

  describe "event_date" do
    it "is required" do
      activity = build_activity(event_date: nil)

      expect(activity).not_to be_valid
      expect(activity.errors[:event_date]).to include("can't be blank")
    end
  end

  describe "visibility" do
    it "defaults to public and is valid" do
      activity = build_activity
      activity.save!

      expect(activity.visibility).to eq("public")
    end

    it "accepts \"private\"" do
      expect(build_activity(visibility: "private")).to be_valid
    end

    it "rejects values outside the allowed list" do
      activity = build_activity(visibility: "secret")

      expect(activity).not_to be_valid
      expect(activity.errors[:visibility]).to include("is not included in the list")
    end
  end

  describe "capacity" do
    it "is optional (nil allowed)" do
      expect(build_activity(capacity: nil)).to be_valid
    end

    it "must be a positive integer" do
      expect(build_activity(capacity: 0)).not_to be_valid
      expect(build_activity(capacity: -5)).not_to be_valid
      expect(build_activity(capacity: 10)).to be_valid
    end

    it "rejects non-integer values" do
      activity = build_activity(capacity: 2.5)

      expect(activity).not_to be_valid
      expect(activity.errors[:capacity]).to include("must be an integer")
    end
  end

  describe "share_token generation" do
    it "is assigned automatically on create" do
      activity = build_activity
      activity.save!

      expect(activity.share_token).to be_present
    end

    it "is unique across activities" do
      first = build_activity
      first.save!
      second = build_activity(city: "Chicago")
      second.save!

      expect(second.share_token).not_to eq(first.share_token)
    end
  end
end
