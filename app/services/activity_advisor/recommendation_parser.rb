# frozen_string_literal: true

module ActivityAdvisor
  # Pulls recommendation payloads out of model replies (fenced or inline JSON).
  class RecommendationParser
    MARKER = '{"recommendations"'

    def self.parse(text)
      new(text).parse
    end

    def self.strip_json(text)
      new(text).strip_json
    end

    def initialize(text)
      @text = text.to_s
    end

    def parse
      payload = load_payload
      return [] unless payload

      Array(payload["recommendations"]).filter_map { |item| build_recommendation(item) }
    rescue JSON::ParserError
      []
    end

    def strip_json
      stripped = @text.dup
      stripped.gsub!(/```json\s*\{.*?\}\s*```/m, "")
      json_string = extract_json_string
      stripped.gsub!(json_string, "") if json_string.present?
      stripped.gsub(/\s{2,}/, " ").strip
    end

    private

    def load_payload
      json_string = extract_json_string
      return nil if json_string.blank?

      JSON.parse(json_string)
    end

    def extract_json_string
      fenced = @text[/```json\s*(\{.*?\})\s*```/m, 1]
      return fenced if fenced.present?

      inline_from_marker
    end

    def inline_from_marker
      start = @text.index(MARKER)
      return nil unless start

      try_parse_from(start)
    end

    def try_parse_from(start)
      substring = @text[start..]
      substring.length.times do |offset|
        candidate = substring[0..offset]
        next unless candidate.end_with?("}")

        parsed = JSON.parse(candidate)
        return candidate if parsed.is_a?(Hash) && parsed.key?("recommendations")
      rescue JSON::ParserError
        next
      end

      nil
    end

    def build_recommendation(item)
      id = item["activity_id"]
      return nil if id.blank?

      activity = Activity.find_by(id: id)
      return nil unless activity

      {
        activity_id: activity.id,
        title: item["title"].presence || activity.title,
        reason: item["reason"].to_s,
        city: activity.city,
        category: activity.category,
        event_date: activity.event_date&.strftime("%b %-d, %Y"),
        url: Rails.application.routes.url_helpers.activity_path(activity)
      }
    end
  end
end
