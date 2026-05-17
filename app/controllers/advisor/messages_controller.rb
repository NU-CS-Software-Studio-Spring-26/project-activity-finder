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
        recommendations: result[:recommendations]
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

    def message_params
      raw = params[:messages]
      return [] unless raw.is_a?(Array)

      raw.map do |entry|
        entry = entry.permit(:role, :content) if entry.respond_to?(:permit)
        { "role" => entry[:role] || entry["role"], "content" => entry[:content] || entry["content"] }
      end
    end
  end
end
