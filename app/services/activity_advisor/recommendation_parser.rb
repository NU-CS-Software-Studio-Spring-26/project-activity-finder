# frozen_string_literal: true

module ActivityAdvisor
  # Pulls structured payloads (recommendations or a create-activity draft) out of
  # model replies, whether the JSON is fenced (```json ... ```) or inline.
  class RecommendationParser
    # Top-level keys the model may emit inside its JSON block.
    PAYLOAD_KEYS = %w[recommendations create_activity].freeze

    def self.parse(text)
      new(text).recommendations
    end

    def self.create_activity(text)
      new(text).create_activity
    end

    def self.strip_json(text)
      new(text).strip_json
    end

    def initialize(text)
      @text = text.to_s
    end

    def recommendations
      payload = load_payload
      return [] unless payload

      seen = []
      Array(payload["recommendations"]).filter_map do |item|
        rec = build_recommendation(item)
        next if rec.nil? || seen.include?(rec[:activity_id])

        seen << rec[:activity_id]
        rec
      end
    rescue JSON::ParserError
      []
    end

    def create_activity
      payload = load_payload
      draft = payload && payload["create_activity"]
      return nil unless draft.is_a?(Hash)

      build_draft(draft)
    rescue JSON::ParserError
      nil
    end

    def strip_json
      stripped = @text.dup
      stripped.gsub!(/```json\s*\{.*?\}\s*```/m, "")
      stripped.gsub!(/```\s*\{.*?\}\s*```/m, "")
      json_string = extract_json_string
      stripped.gsub!(json_string, "") if json_string.present?
      stripped.gsub(/\s{2,}/, " ").strip
    end

    private

    def load_payload
      @load_payload ||= begin
        json_string = extract_json_string
        json_string.present? ? JSON.parse(json_string) : nil
      end
    end

    def extract_json_string
      fenced = @text[/```(?:json)?\s*(\{.*?\})\s*```/m, 1]
      return fenced if fenced.present? && payload_object?(fenced)

      inline_payload
    end

    # Scans for the first inline JSON object that carries one of our known keys.
    def inline_payload
      PAYLOAD_KEYS.filter_map { |key| try_parse_from_marker(%(\{"#{key}")) }.first ||
        PAYLOAD_KEYS.filter_map { |key| try_parse_from_marker(%("#{key}")) }.first
    end

    def try_parse_from_marker(marker)
      start = @text.index(marker)
      return nil unless start

      # Back up to the opening brace of the enclosing object.
      brace = @text.rindex("{", start) || start
      try_parse_from(brace)
    end

    def try_parse_from(start)
      substring = @text[start..]
      substring.length.times do |offset|
        candidate = substring[0..offset]
        next unless candidate.end_with?("}")

        parsed = JSON.parse(candidate)
        return candidate if payload?(parsed)
      rescue JSON::ParserError
        next
      end

      nil
    end

    def payload_object?(string)
      payload?(JSON.parse(string))
    rescue JSON::ParserError
      false
    end

    def payload?(parsed)
      parsed.is_a?(Hash) && PAYLOAD_KEYS.any? { |key| parsed.key?(key) }
    end

    def build_recommendation(item)
      return nil unless item.is_a?(Hash)

      id = item["activity_id"]
      return nil if id.blank?

      activity = Activity.find_by(id: id)
      return nil unless activity

      {
        activity_id: activity.id,
        # Always trust the catalog for display fields so the card can never
        # show a title/city/date the model hallucinated or mismatched.
        title: activity.title,
        reason: item["reason"].to_s.strip,
        city: activity.city,
        category: activity.category,
        event_date: activity.event_date&.strftime("%b %-d, %Y"),
        url: Rails.application.routes.url_helpers.activity_path(activity)
      }
    end

    # Sanitizes a create-activity draft for use as new-activity form prefill.
    # Only known-valid category/city values are passed through; the user still
    # reviews and submits the real form, so this is intentionally lenient.
    def build_draft(draft)
      title = draft["title"].to_s.strip
      return nil if title.blank?

      {
        title: title.truncate(120),
        description: draft["description"].to_s.strip.presence,
        category: sanitize_category(draft["category"]),
        city: sanitize_city(draft["city"]),
        event_date: sanitize_date(draft["event_date"]),
        capacity: sanitize_capacity(draft["capacity"])
      }.compact
    end

    def sanitize_category(value)
      value = value.to_s.strip
      Activity::CATEGORIES.find { |c| c.casecmp?(value) }
    end

    def sanitize_city(value)
      value = value.to_s.strip
      Activity::ALLOWED_CITIES.find { |c| c.casecmp?(value) }
    end

    def sanitize_date(value)
      date = Date.iso8601(value.to_s)
      date >= Date.current ? date.iso8601 : nil
    rescue ArgumentError, TypeError
      nil
    end

    def sanitize_capacity(value)
      capacity = Integer(value, exception: false)
      capacity if capacity && capacity.positive?
    end
  end
end
