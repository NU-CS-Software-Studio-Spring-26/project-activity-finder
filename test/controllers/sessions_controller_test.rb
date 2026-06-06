require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      name: "Test User",
      email: "test@example.com",
      password: "password",
      password_confirmation: "password"
    )
  end

  test "should get login page" do
    get login_path
    assert_response :success
  end

  test "should login with valid credentials" do
    post login_path, params: {
      email: @user.email,
      password: "password"
    }

    assert_redirected_to root_path
    follow_redirect!
    follow_redirect!
    assert_match "Logged in successfully", response.body
  end

  test "should not login with invalid credentials" do
    post login_path, params: {
      email: @user.email,
      password: "wrongpassword"
    }

    assert_response :unprocessable_entity
    assert_match "Invalid email or password", response.body
  end

  test "should not login with unknown email and show generic message" do
    post login_path, params: {
      email: "notregistered@example.com",
      password: "anypassword"
    }

    assert_response :unprocessable_entity
    assert_match "Invalid email or password", response.body
  end

  test "login matches email case-insensitively" do
    post login_path, params: {
      email: @user.email.upcase,
      password: "password"
    }

    assert_redirected_to root_path
  end

  test "should logout successfully" do
    post login_path, params: {
      email: @user.email,
      password: "password"
    }

    delete logout_path

    assert_redirected_to login_path
    follow_redirect!
    assert_match "Logged out successfully", response.body
  end

  test "google oauth callback creates user and signs in" do
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "integration-uid",
      info: { email: "integration_oauth@example.com", name: "Integration OAuth" },
      extra: { raw_info: { "email_verified" => true } }
    )

    get "/auth/google_oauth2/callback"

    assert_redirected_to root_path
    follow_redirect!
    follow_redirect!
    assert_match "Account successfully created, Integration OAuth", response.body

    user = User.find_by!(email: "integration_oauth@example.com")
    assert_equal "google_oauth2", user.provider
    assert_equal "integration-uid", user.uid
  ensure
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  test "google oauth callback links existing user by email" do
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "link-uid",
      info: { email: @user.email, name: @user.name },
      extra: { raw_info: { "email_verified" => true } }
    )

    get "/auth/google_oauth2/callback"

    assert_redirected_to root_path
    follow_redirect!
    follow_redirect!
    assert_match "Welcome back, Test User", response.body
    @user.reload
    assert_equal "google_oauth2", @user.provider
    assert_equal "link-uid", @user.uid
  ensure
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end
end
