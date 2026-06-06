require "test_helper"

# Exercises the dependency-free bot prevention (honeypot + time trap) wired into
# the public create forms: signup (users#create) and activity creation.
class BotPreventionTest < ActionDispatch::IntegrationTest
  def signup_params(extra = {})
    {
      user: {
        name: "Real Person",
        email: "real.person@example.com",
        password: "password",
        password_confirmation: "password"
      }
    }.merge(extra)
  end

  test "signup succeeds with a blank honeypot and a valid timestamp" do
    assert_difference("User.count", 1) do
      post users_url, params: signup_params(bot_prevention_params)
    end
    assert_redirected_to root_path
  end

  test "signup is blocked when the honeypot is filled" do
    assert_no_difference("User.count") do
      post users_url, params: signup_params(
        bot_prevention_params.merge(BotPrevention::HONEYPOT_FIELD => "spam@bot.net")
      )
    end
    assert_response :unprocessable_entity
    assert_match(/verify your submission/i, response.body)
  end

  test "signup is blocked when the timestamp is missing" do
    assert_no_difference("User.count") do
      post users_url, params: signup_params
    end
    assert_response :unprocessable_entity
  end

  test "signup is blocked when submitted faster than a human could" do
    assert_no_difference("User.count") do
      post users_url, params: signup_params(bot_prevention_params(rendered_at: Time.current))
    end
    assert_response :unprocessable_entity
  end

  test "signup is blocked when the timestamp signature is forged" do
    assert_no_difference("User.count") do
      post users_url, params: signup_params(
        BotPrevention::TIMESTAMP_FIELD => "not-a-valid-signed-token"
      )
    end
    assert_response :unprocessable_entity
  end

  test "activity creation is blocked when the honeypot is filled" do
    user = User.create!(
      name: "Host",
      email: "host@example.com",
      password: "password",
      password_confirmation: "password"
    )
    post login_path, params: { email: user.email, password: "password" }

    assert_no_difference("Activity.count") do
      post activities_url, params: {
        activity: {
          title: "Morning Run",
          city: "Seattle",
          category: "Test",
          event_date: Date.today
        }
      }.merge(bot_prevention_params).merge(BotPrevention::HONEYPOT_FIELD => "x")
    end
    assert_response :unprocessable_entity
  end
end
