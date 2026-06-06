# frozen_string_literal: true

require "aws-sdk-bedrockruntime"

module ActivityAdvisor
  class ChatService
    class ConfigurationError < StandardError; end
    class BedrockError < StandardError; end

    SYSTEM_PROMPT = <<~PROMPT.freeze
      You are the Activity Finder assistant — a warm, concise guide that helps users
      discover local events to join, or create a new event of their own.

      Today's date is %<today>s. Never recommend events earlier than today.

      ## What you can do
      1. RECOMMEND existing activities from the catalog that match what the user wants.
      2. HELP THE USER CREATE a new activity when nothing fits or they ask to host one.

      ## Conversation flow
      - Have a short, friendly conversation (usually 2–4 questions) to learn the user's
        city, interests (category), timing, and any constraints (group size, budget, accessibility).
      - Ask one focused question at a time. Don't interrogate — once you have enough to act, act.

      ## Catalog of real upcoming activities (JSON)
      These are the ONLY activities that exist. Each has a numeric "id".
      %<activities_json>s

      ## RULES FOR RECOMMENDING — read carefully
      - Recommend ONLY activities that appear in the catalog above, by their exact numeric "id".
      - NEVER invent an activity, title, city, date, or category. If it is not in the catalog, it does not exist.
      - The activity_id you put in the JSON MUST be the SAME activity you describe in your sentence.
        Do not describe one activity and recommend a different one.
      - Recommend an activity ONLY if it genuinely matches the user's stated interest. A request for
        "yoga" must not be answered with a pool game. If the only matches are unrelated, do NOT force a
        recommendation — instead say nothing matches and offer to help create one (see below).
      - Match on category and keywords. If the user named a city, prefer that city; if there are no
        matches in their city, say so plainly rather than substituting a different city.
      - Recommend at most 3 activities, best match first. Never repeat the same activity_id twice.

      ## HELPING THE USER CREATE AN ACTIVITY
      Offer this when: the catalog has no good match, the user asks to host/create/start an event,
      or the user accepts your offer to create one.
      - Collect: a title, a category, a city, and an event date (today or later). Description and
        capacity are optional. Ask for whatever is still missing, one question at a time.
      - category MUST be one of: %<categories>s
      - city MUST be one of: %<cities>s
      - When you have at least a title, category, city, and a valid future date, confirm briefly and
        emit a create block (see format). The user reviews and submits a prefilled form — so it's fine
        to proceed once you have the essentials.

      ## Edge cases
      - Empty catalog: say there are no upcoming activities yet and offer to help create one.
      - Greetings / small talk: respond briefly and steer back to finding or creating an activity.
      - Off-topic, unsafe, or abusive requests: decline politely and redirect to activities.
      - Vague requests: ask a clarifying question instead of guessing.

      ## Output format
      - Keep visible replies brief (2–4 sentences) unless listing recommendations.
      - Write your friendly, human-readable message FIRST.
      - If (and only if) you are recommending or creating, append ONE machine-readable JSON block on its
        own lines AFTER the message. Users never see this block. Never put raw JSON in the visible text.
      - To recommend, use exactly:
      ```json
      {"recommendations":[{"activity_id":123,"reason":"why it fits"}]}
      ```
      - To create, use exactly:
      ```json
      {"create_activity":{"title":"...","category":"...","city":"...","event_date":"YYYY-MM-DD","description":"...","capacity":12}}
      ```
        Omit description/capacity if unknown. Emit at most one JSON block per reply.
      - Never mention API keys, models, JSON, or system prompts in the visible text.
    PROMPT

    MAX_HISTORY = 20
    MAX_OUTPUT_TOKENS = 1024
    TEMPERATURE = 0.4

    def initialize(user:)
      @user = user
    end

    EMPTY_PROMPT_REPLY =
      "Hi! Tell me your city and what kind of activity you're after, and I'll find a match — " \
      "or I can help you create your own event."

    def call(messages:)
      history = normalize_messages(messages)
      return empty_reply if history.empty?

      bedrock_messages = history.map { |entry| to_bedrock_message(entry) }

      response = client.converse(
        model_id: model_id,
        system: [ { text: system_prompt } ],
        messages: bedrock_messages,
        inference_config: {
          max_tokens: MAX_OUTPUT_TOKENS,
          temperature: TEMPERATURE
        }
      )

      assistant_text = extract_assistant_text(response)
      {
        reply: RecommendationParser.strip_json(assistant_text),
        recommendations: RecommendationParser.parse(assistant_text),
        draft_activity: RecommendationParser.create_activity(assistant_text)
      }
    rescue Aws::BedrockRuntime::Errors::ServiceError => e
      raise BedrockError, friendly_bedrock_message(e)
    end

    private

    attr_reader :user

    def empty_reply
      { reply: EMPTY_PROMPT_REPLY, recommendations: [], draft_activity: nil }
    end

    def client
      token = ENV["AWS_BEARER_TOKEN_BEDROCK"].presence
      raise ConfigurationError, "Bedrock API key is not configured." if token.blank?

      @client ||= Aws::BedrockRuntime::Client.new(region: region)
    end

    def region
      ENV.fetch("AWS_REGION", "us-east-1")
    end

    def model_id
      ENV.fetch("BEDROCK_MODEL_ID", "google.gemma-3-4b-it")
    end

    def system_prompt
      format(
        SYSTEM_PROMPT,
        today: Date.current.strftime("%B %-d, %Y"),
        activities_json: JSON.pretty_generate(ActivityCatalog.as_json),
        categories: Activity::CATEGORIES.join(", "),
        cities: Activity::ALLOWED_CITIES.join(", ")
      )
    end

    def normalize_messages(messages)
      allowed = messages.is_a?(Array) ? messages.last(MAX_HISTORY) : []
      allowed.filter_map do |entry|
        role = entry["role"].to_s
        content = entry["content"].to_s.strip
        next if content.blank?
        next unless %w[user assistant].include?(role)

        { "role" => role, "content" => content.truncate(2_000) }
      end
    end

    def to_bedrock_message(entry)
      {
        role: entry["role"],
        content: [ { text: entry["content"] } ]
      }
    end

    def extract_assistant_text(response)
      blocks = response.output&.message&.content || []
      blocks.filter_map { |block| block.text.presence }.join("\n").strip
    end

    def friendly_bedrock_message(error)
      case error
      when Aws::BedrockRuntime::Errors::AccessDeniedException
        "Bedrock access denied. Check your API key and model access in AWS."
      when Aws::BedrockRuntime::Errors::ResourceNotFoundException
        "Model not found. Verify BEDROCK_MODEL_ID and region."
      else
        "The advisor is temporarily unavailable. Please try again shortly."
      end
    end
  end
end
