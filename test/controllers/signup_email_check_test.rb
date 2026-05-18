require "test_helper"

class SignupEmailCheckTest < ActionDispatch::IntegrationTest
  setup do
    @existing = User.create!(
      name: "Existing User",
      email: "taken@example.com",
      password: "password",
      password_confirmation: "password"
    )
  end

  test "check_email returns available for new address" do
    get check_email_signup_path, params: { email: "new@example.com" }, as: :json
    assert_response :success
    assert JSON.parse(response.body)["available"]
  end

  test "check_email returns unavailable for registered address" do
    get check_email_signup_path, params: { email: @existing.email }, as: :json
    assert_response :success
    assert_not JSON.parse(response.body)["available"]
  end

  test "check_email is case insensitive" do
    get check_email_signup_path, params: { email: "TAKEN@example.com" }, as: :json
    assert_response :success
    assert_not JSON.parse(response.body)["available"]
  end

  test "check_email rejects invalid format" do
    get check_email_signup_path, params: { email: "not-an-email" }, as: :json
    assert_response :success
    assert_not JSON.parse(response.body)["available"]
  end

  test "check_email does not require login" do
    get check_email_signup_path, params: { email: "guest@example.com" }, as: :json
    assert_response :success
  end
end
