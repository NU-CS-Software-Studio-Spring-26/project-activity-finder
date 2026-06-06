ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

OmniAuth.config.test_mode = true

module ActiveSupport
  class TestCase
    # fork() is unavailable on Windows; parallelize on Unix-like systems only.
    parallelize(workers: :number_of_processors) unless Gem.win_platform?

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...

    # Bot-prevention fields a real form would carry: a blank honeypot and a
    # signed render timestamp old enough to clear the time trap. Merge into
    # create-form POST params so legitimate submissions aren't flagged as bots.
    def bot_prevention_params(rendered_at: 1.minute.ago)
      verifier = Rails.application.message_verifier(:bot_prevention)
      {
        BotPrevention::TIMESTAMP_FIELD =>
          verifier.generate(rendered_at.to_f, purpose: :form_render_time)
      }
    end
  end
end
