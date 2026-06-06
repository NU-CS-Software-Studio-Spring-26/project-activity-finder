# frozen_string_literal: true

require "test_helper"

module ActivityAdvisor
  class RecommendationParserTest < ActiveSupport::TestCase
    setup do
      @activity = activities(:one)
      @activity.update_columns(
        user_id: users(:one).id,
        title: "Sunrise Yoga",
        city: "Seattle",
        category: "Fitness Class",
        event_date: Date.current + 3.days
      )
    end

    test "parses inline recommendations json and strips it from reply text" do
      raw = <<~TEXT.squish
        Great picks for you!
        {"recommendations":[{"activity_id":#{@activity.id},"reason":"Casual and fun."}]}
      TEXT

      parsed = RecommendationParser.parse(raw)
      assert_equal 1, parsed.length
      assert_equal @activity.id, parsed.first[:activity_id]
      assert_equal "Casual and fun.", parsed.first[:reason]

      stripped = RecommendationParser.strip_json(raw)
      assert_includes stripped, "Great picks"
      assert_not_includes stripped, "recommendations"
      assert_not_includes stripped, "activity_id"
    end

    test "parses fenced json block" do
      raw = <<~TEXT
        Here you go!
        ```json
        {"recommendations":[{"activity_id":#{@activity.id},"reason":"Morning jog."}]}
        ```
      TEXT

      assert_equal 1, RecommendationParser.parse(raw).length
      assert_not_includes RecommendationParser.strip_json(raw), "```"
    end

    test "display fields always come from the catalog, not the model" do
      # The model lies about the title/city; the parser must ignore those and
      # use the real activity record. This is the core #137 guardrail.
      raw = %({"recommendations":[{"activity_id":#{@activity.id},"title":"Pool Game","city":"Evanston","reason":"x"}]})

      rec = RecommendationParser.parse(raw).first
      assert_equal "Sunrise Yoga", rec[:title]
      assert_equal "Seattle", rec[:city]
      assert_equal "Fitness Class", rec[:category]
    end

    test "drops recommendations for activities that do not exist" do
      raw = %({"recommendations":[{"activity_id":999999,"reason":"nope"},{"activity_id":#{@activity.id},"reason":"ok"}]})

      parsed = RecommendationParser.parse(raw)
      assert_equal [ @activity.id ], parsed.map { |r| r[:activity_id] }
    end

    test "de-duplicates repeated activity ids" do
      raw = %({"recommendations":[{"activity_id":#{@activity.id},"reason":"a"},{"activity_id":#{@activity.id},"reason":"b"}]})

      assert_equal 1, RecommendationParser.parse(raw).length
    end

    test "returns empty when there is no json payload" do
      assert_empty RecommendationParser.parse("Just a friendly chat, no picks yet.")
      assert_nil RecommendationParser.create_activity("Just a friendly chat.")
    end

    test "extracts a create_activity draft with sanitized fields" do
      raw = <<~TEXT
        Let's set this up!
        ```json
        {"create_activity":{"title":"Morning Yoga","category":"fitness class","city":"seattle","event_date":"#{(Date.current + 5.days).iso8601}","capacity":12}}
        ```
      TEXT

      draft = RecommendationParser.create_activity(raw)
      assert_equal "Morning Yoga", draft[:title]
      assert_equal "Fitness Class", draft[:category] # canonical casing from catalog
      assert_equal "Seattle", draft[:city]
      assert_equal 12, draft[:capacity]
      assert_not_includes RecommendationParser.strip_json(raw), "create_activity"
    end

    test "create_activity draft rejects invalid category, city, and past dates" do
      raw = %({"create_activity":{"title":"Mystery Event","category":"Underwater Basket Weaving","city":"Atlantis","event_date":"2000-01-01","capacity":-5}})

      draft = RecommendationParser.create_activity(raw)
      assert_equal "Mystery Event", draft[:title]
      assert_nil draft[:category]
      assert_nil draft[:city]
      assert_nil draft[:event_date]
      assert_nil draft[:capacity]
    end

    test "create_activity draft requires a title" do
      raw = %({"create_activity":{"category":"Hike","city":"Seattle"}})
      assert_nil RecommendationParser.create_activity(raw)
    end
  end
end
