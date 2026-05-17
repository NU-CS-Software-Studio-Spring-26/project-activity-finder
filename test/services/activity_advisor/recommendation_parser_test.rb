# frozen_string_literal: true

require "test_helper"

module ActivityAdvisor
  class RecommendationParserTest < ActiveSupport::TestCase
    test "parses inline recommendations json and strips it from reply text" do
      activity = activities(:one)
      activity.update_columns(user_id: users(:one).id, event_date: Date.current + 3.days)

      raw = <<~TEXT.squish
        Great picks for you!
        {"recommendations":[{"activity_id":#{activity.id},"title":"Coffee Meetup","reason":"Casual and fun."}]}
      TEXT

      parsed = RecommendationParser.parse(raw)
      assert_equal 1, parsed.length
      assert_equal activity.id, parsed.first[:activity_id]
      assert_equal "Coffee Meetup", parsed.first[:title]

      stripped = RecommendationParser.strip_json(raw)
      assert_includes stripped, "Great picks"
      assert_not_includes stripped, "recommendations"
      assert_not_includes stripped, "activity_id"
    end

    test "parses fenced json block" do
      activity = activities(:one)
      activity.update_columns(user_id: users(:one).id, event_date: Date.current + 3.days)

      raw = <<~TEXT
        Here you go!
        ```json
        {"recommendations":[{"activity_id":#{activity.id},"title":"Run Club","reason":"Morning jog."}]}
        ```
      TEXT

      assert_equal 1, RecommendationParser.parse(raw).length
      assert_not_includes RecommendationParser.strip_json(raw), "```"
    end
  end
end
