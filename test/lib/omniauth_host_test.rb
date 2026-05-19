require "test_helper"
require Rails.root.join("lib/omniauth_host")

class OmniauthHostTest < ActiveSupport::TestCase
  setup do
    @original_app_host = ENV["APP_HOST"]
    @original_app_url = ENV["APP_URL"]
    @original_heroku = ENV["HEROKU_APP_NAME"]
  end

  teardown do
    ENV["APP_HOST"] = @original_app_host
    ENV["APP_URL"] = @original_app_url
    ENV["HEROKU_APP_NAME"] = @original_heroku
  end

  test "normalize adds https when scheme missing" do
    assert_equal "https://my-app.herokuapp.com", OmniauthHost.normalize("my-app.herokuapp.com")
  end

  test "resolve uses APP_HOST when set" do
    ENV["APP_HOST"] = "https://example.herokuapp.com"
    ENV["HEROKU_APP_NAME"] = nil

    assert_equal "https://example.herokuapp.com", OmniauthHost.resolve
  end

  test "resolve uses HEROKU_APP_NAME when APP_HOST unset outside development" do
    ENV["APP_HOST"] = nil
    ENV["HEROKU_APP_NAME"] = "activity-finder-8073ba70e16c"

    assert_equal "https://activity-finder-8073ba70e16c.herokuapp.com", OmniauthHost.resolve
  end
end
