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
  end
end
