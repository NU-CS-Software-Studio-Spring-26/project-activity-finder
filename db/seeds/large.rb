# frozen_string_literal: true

# Bulk data for local development and pagination/performance testing.
# Run after the default seed:  bin/rails db:seed && bin/rails db:seed:large
#
# Generated accounts use email loadtest-N@example.com with password "password".

module Seeds
  module Large
    BATCH_SIZE = 500
    USER_COUNT = Integer(ENV.fetch("SEED_LARGE_USERS", 1_200))
    ACTIVITY_COUNT = Integer(ENV.fetch("SEED_LARGE_ACTIVITIES", 1_500))
    SIGNUP_COUNT = Integer(ENV.fetch("SEED_LARGE_SIGNUPS", 2_500))
    EMAIL_DOMAIN = "example.com"
    EMAIL_PREFIX = "loadtest"

    CATEGORIES = [
      "Hike", "Food Crawl", "Coffee Meetup", "Trivia Night", "Art Walk",
      "Fitness Class", "Farmers Market"
    ].freeze

    CITIES = Activity::ALLOWED_CITIES

    LOCATIONS = [
      "Community Center", "City Park", "Downtown Plaza", "Riverfront Trail",
      "Student Union", "Main Street", "Lakefront Pavilion"
    ].freeze

    module_function

    def run
      password_digest = BCrypt::Password.create("password")
      now = Time.current

      clear_previous_loadtest_data!

      puts "Seeding #{USER_COUNT} loadtest users…"
      user_ids = insert_users(password_digest, now)
      puts "  → #{user_ids.size} users"

      host_ids = User.pluck(:id)
      puts "Seeding #{ACTIVITY_COUNT} activities…"
      activity_ids = insert_activities(host_ids, now)
      puts "  → #{activity_ids.size} activities"

      puts "Seeding #{SIGNUP_COUNT} activity signups…"
      signup_count = insert_signups(activity_ids, host_ids, now)
      puts "  → #{signup_count} signups"

      puts "Done. Totals: #{User.count} users, #{Activity.count} activities, #{ActivitySignup.count} signups"
      puts "Loadtest login: #{EMAIL_PREFIX}-1@#{EMAIL_DOMAIN} / password"
    end

    def clear_previous_loadtest_data!
      loadtest_users = User.where("email LIKE ?", "#{EMAIL_PREFIX}-%@#{EMAIL_DOMAIN}")
      return if loadtest_users.none?

      ids = loadtest_users.pluck(:id)
      ActivitySignup.where(user_id: ids).delete_all
      ActivitySignup.where(activity_id: Activity.where(user_id: ids).select(:id)).delete_all
      Activity.where(user_id: ids).delete_all
      loadtest_users.delete_all
      puts "Removed previous loadtest users and their activities."
    end

    def insert_users(password_digest, now)
      rows = USER_COUNT.times.map do |n|
        {
          name: "Loadtest User #{n + 1}",
          email: "#{EMAIL_PREFIX}-#{n + 1}@#{EMAIL_DOMAIN}",
          password_digest: password_digest,
          admin: false,
          provider: nil,
          uid: nil,
          created_at: now,
          updated_at: now
        }
      end

      ids = []
      rows.each_slice(BATCH_SIZE) do |batch|
        result = User.insert_all(batch, returning: %w[id])
        ids.concat(result.rows.flatten)
      end
      ids
    end

    def insert_activities(host_ids, now)
      rng = Random.new(42)
      rows = ACTIVITY_COUNT.times.map do |n|
        event_date = Date.today + rng.rand(1..180)
        {
          title: "#{CATEGORIES.sample(random: rng)} #{n + 1}",
          description: "Auto-generated activity for development and pagination testing.",
          location: LOCATIONS.sample(random: rng),
          city: CITIES.sample(random: rng),
          category: CATEGORIES.sample(random: rng),
          event_date: event_date,
          capacity: [ nil, rng.rand(10..80) ].sample(random: rng),
          user_id: host_ids.sample(random: rng),
          created_at: now,
          updated_at: now
        }
      end

      ids = []
      rows.each_slice(BATCH_SIZE) do |batch|
        result = Activity.insert_all(batch, returning: %w[id])
        ids.concat(result.rows.flatten)
      end
      ids
    end

    def insert_signups(activity_ids, user_ids, now)
      return 0 if activity_ids.empty? || user_ids.empty?

      rng = Random.new(99)
      pairs = Set.new
      target = [ SIGNUP_COUNT, activity_ids.size * user_ids.size ].min

      while pairs.size < target
        pairs << [ activity_ids.sample(random: rng), user_ids.sample(random: rng) ]
      end

      rows = pairs.map do |activity_id, user_id|
        {
          activity_id: activity_id,
          user_id: user_id,
          created_at: now,
          updated_at: now
        }
      end

      # Skip pairs that already exist (e.g. host signed up for own event)
      existing = ActivitySignup.where(activity_id: activity_ids)
        .pluck(:activity_id, :user_id)
        .to_set
      rows.reject! { |r| existing.include?([ r[:activity_id], r[:user_id] ]) }

      rows.each_slice(BATCH_SIZE) do |batch|
        ActivitySignup.insert_all(batch)
      end
      rows.size
    end
  end
end
