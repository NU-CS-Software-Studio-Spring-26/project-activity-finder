# frozen_string_literal: true

require "test_helper"

module ActivityAdvisor
  class ActivityCatalogTest < ActiveSupport::TestCase
    test "serializes upcoming activities with signup metadata" do
      activity = activities(:one)
      activity.update_columns(
        user_id: users(:one).id,
        event_date: Date.current + 7.days,
        capacity: 10
      )

      payload = ActivityCatalog.as_json
      entry = payload.find { |row| row[:id] == activity.id }

      assert entry
      assert_equal activity.title, entry[:title]
      assert_equal 10, entry[:capacity]
      assert entry.key?(:spots_left)
    end
  end
end
