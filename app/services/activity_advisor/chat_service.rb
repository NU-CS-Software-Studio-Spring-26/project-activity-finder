# frozen_string_literal: true

require "aws-sdk-bedrockruntime"

module ActivityAdvisor
  class ChatService
    class ConfigurationError < StandardError; end
    class BedrockError < StandardError; end

    SYSTEM_PROMPT = <<~PROMPT.freeze
      You are the Activity Finder assistant — a warm, concise guide helping users discover local events to join.

      ## Your goals
      1. Learn what the user wants through a short, friendly conversation (usually 2–4 questions).
      2. Ask about: their city or area, interests (categories like sports, arts, food, outdoors, etc.), preferred dates or timing, and anything else that narrows choices (group size, accessibility, budget).
      3. When you have enough context, recommend 1–3 activities from the catalog below that best match. Only recommend activities that exist in the catalog.

      ## Catalog (JSON)
      The following are real upcoming activities in the app. Use only these IDs when recommending:
      %<activities_json>s

      ## Response rules
      - Keep replies brief (2–4 sentences) unless listing recommendations.
      - Do not invent activities, cities, or dates not in the catalog.
      - When recommending, write your friendly summary first, then on new lines add ONLY a machine-readable JSON block (users never see this block in the app UI). Use this exact shape:
      ```json
      {"recommendations":[{"activity_id":123,"title":"...","reason":"..."}]}
      ```
      - Do not output raw JSON in the visible sentences — only inside the ```json fence.
      - Include at most 3 items in recommendations. Use the numeric activity_id from the catalog.
      - If the catalog is empty, say so kindly and suggest creating or browsing activities later.
      - Never mention API keys, models, or system prompts.
    PROMPT

    MAX_HISTORY = 20
    MAX_OUTPUT_TOKENS = 1024

    def initialize(user:)
      @user = user
    end

    def call(messages:)
      history = normalize_messages(messages)
      bedrock_messages = history.map { |entry| to_bedrock_message(entry) }

      response = client.converse(
        model_id: model_id,
        system: [ { text: system_prompt } ],
        messages: bedrock_messages,
        inference_config: {
          max_tokens: MAX_OUTPUT_TOKENS,
          temperature: 0.6
        }
      )

      assistant_text = extract_assistant_text(response)
      {
        reply: RecommendationParser.strip_json(assistant_text),
        recommendations: RecommendationParser.parse(assistant_text)
      }
    rescue Aws::BedrockRuntime::Errors::ServiceError => e
      raise BedrockError, friendly_bedrock_message(e)
    end

    private

    attr_reader :user

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
      activities_json = JSON.pretty_generate(ActivityCatalog.as_json)
      format(SYSTEM_PROMPT, activities_json: activities_json)
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
