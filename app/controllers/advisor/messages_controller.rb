# frozen_string_literal: true

module Advisor
  class MessagesController < ApplicationController
    before_action :require_login

    def create
      result = ActivityAdvisor::ChatService.new(user: current_user).call(
        messages: message_params
      )

      render json: {
        reply: result[:reply],
        recommendations: result[:recommendations],
        draft_activity: draft_payload(result[:draft_activity])
      }
    rescue ActivityAdvisor::ChatService::ConfigurationError => e
      render json: { error: e.message }, status: :service_unavailable
    rescue ActivityAdvisor::ChatService::BedrockError => e
      render json: { error: e.message }, status: :bad_gateway
    rescue StandardError
      Rails.logger.error("[ActivityAdvisor] #{ $ERROR_INFO.class }: #{ $ERROR_INFO.message }")
      render json: { error: "Something went wrong. Please try again." }, status: :internal_server_error
    end

    private

    # Turns a sanitized draft into a payload the chat widget can render: a short
    # summary plus a prefill URL for the real new-activity form (the user still
    # reviews and submits it, so nothing is created without confirmation).
    def draft_payload(draft)
      return nil if draft.blank?

      {
        title: draft[:title],
        category: draft[:category],
        city: draft[:city],
        event_date: draft[:event_date],
        url: new_activity_path(activity: draft)
      }
    end

    def message_params
      permitted = params.permit(messages: [ :role, :content ])
      Array(permitted[:messages]).map do |entry|
        { "role" => entry[:role], "content" => entry[:content] }
      end
    end
  end
end
