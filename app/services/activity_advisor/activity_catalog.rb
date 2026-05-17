# frozen_string_literal: true

module ActivityAdvisor
  # Serializes upcoming activities for the advisor system prompt.
  class ActivityCatalog
    MAX_ACTIVITIES = 60

    def self.as_json
      new.as_json
    end

    def as_json
      activities
    end

    private

    def activities
      signup_counts = ActivitySignup.group(:activity_id).count

      Activity
        .where("event_date >= ?", Date.current)
        .order(event_date: :asc)
        .limit(MAX_ACTIVITIES)
        .map do |activity|
          serialize(activity, signup_counts[activity.id].to_i)
        end
    end

    def serialize(activity, attendee_count)
      capacity = activity.capacity
      spots_left = capacity.present? ? [ capacity - attendee_count, 0 ].max : nil

      {
        id: activity.id,
        title: activity.title,
        description: activity.description,
        city: activity.city,
        location: activity.location,
        category: activity.category,
        event_date: activity.event_date&.iso8601,
        capacity: capacity,
        attendee_count: attendee_count,
        spots_left: spots_left,
        full: capacity.present? && spots_left.zero?
      }
    end
  end
end
