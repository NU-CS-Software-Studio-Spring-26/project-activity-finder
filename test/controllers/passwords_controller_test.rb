require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      name: "Grace",
      email: "grace@example.com",
      password: "password",
      password_confirmation: "password"
    )
    ActionMailer::Base.deliveries.clear
  end

  # ---------------------------------------------------------------------------
  # GET /password/forgot
  # ---------------------------------------------------------------------------

  test "should get forgot password page" do
    get forgot_password_path
    assert_response :success
    assert_select "h1", text: "Reset your password"
  end

  test "logged-in user is redirected away from forgot password page" do
    post login_path, params: { email: @user.email, password: "password" }
    get forgot_password_path
    assert_redirected_to root_path
  end

  # ---------------------------------------------------------------------------
  # POST /password/forgot
  # ---------------------------------------------------------------------------

  test "sends reset email when email is registered" do
    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      post forgot_password_path, params: { email: @user.email }
    end

    mail = ActionMailer::Base.deliveries.last
    assert_equal [ @user.email ], mail.to
    assert_match "Reset your Open Scene password", mail.subject
  end

  test "reset email contains a valid reset link" do
    post forgot_password_path, params: { email: @user.email }

    mail = ActionMailer::Base.deliveries.last
    body = mail.body.parts.map(&:decoded).join
    assert_match %r{/password/reset/}, body
  end

  test "does NOT send email when address is unknown" do
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      post forgot_password_path, params: { email: "nobody@example.com" }
    end
  end

  test "shows same success message whether or not email is registered" do
    post forgot_password_path, params: { email: @user.email }
    assert_redirected_to login_path
    assert_match "If that email is registered", flash[:notice]

    post forgot_password_path, params: { email: "nobody@example.com" }
    assert_redirected_to login_path
    assert_match "If that email is registered", flash[:notice]
  end

  test "email lookup is case-insensitive" do
    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      post forgot_password_path, params: { email: @user.email.upcase }
    end
  end

  # ---------------------------------------------------------------------------
  # GET /password/reset/:token
  # ---------------------------------------------------------------------------

  test "shows reset form with a valid token" do
    token = @user.password_reset_token
    get edit_password_reset_path(token)
    assert_response :success
    assert_select "h1", text: "Choose a new password"
  end

  test "redirects to forgot page with an invalid token" do
    get edit_password_reset_path("not-a-real-token")
    assert_redirected_to forgot_password_path
    assert_match "invalid or has expired", flash[:alert]
  end

  test "redirects to forgot page after token is invalidated by password change" do
    token = @user.password_reset_token
    @user.update!(password: "newpass1", password_confirmation: "newpass1")

    get edit_password_reset_path(token)
    assert_redirected_to forgot_password_path
    assert_match "invalid or has expired", flash[:alert]
  end

  # ---------------------------------------------------------------------------
  # PATCH /password/reset/:token
  # ---------------------------------------------------------------------------

  test "updates password with valid token and matching confirmation" do
    token = @user.password_reset_token

    patch edit_password_reset_path(token), params: {
      user: { password: "hunter2", password_confirmation: "hunter2" }
    }

    assert_redirected_to login_path
    assert_match "Password updated", flash[:notice]
    assert @user.reload.authenticate("hunter2"), "New password should work"
  end

  test "can log in with the new password after reset" do
    token = @user.password_reset_token
    patch edit_password_reset_path(token), params: {
      user: { password: "freshpass", password_confirmation: "freshpass" }
    }

    post login_path, params: { email: @user.email, password: "freshpass" }
    assert_redirected_to root_path
  end

  test "old password no longer works after reset" do
    token = @user.password_reset_token
    patch edit_password_reset_path(token), params: {
      user: { password: "freshpass", password_confirmation: "freshpass" }
    }

    post login_path, params: { email: @user.email, password: "password" }
    assert_response :unprocessable_entity
  end

  test "rejects update when password confirmation does not match" do
    token = @user.password_reset_token

    patch edit_password_reset_path(token), params: {
      user: { password: "hunter2", password_confirmation: "mismatch" }
    }

    assert_response :unprocessable_entity
    assert @user.reload.authenticate("password"), "Original password should be unchanged"
  end

  test "rejects update when new password is too short" do
    token = @user.password_reset_token

    patch edit_password_reset_path(token), params: {
      user: { password: "abc", password_confirmation: "abc" }
    }

    assert_response :unprocessable_entity
    assert @user.reload.authenticate("password"), "Original password should be unchanged"
  end

  test "rejects update with an invalid token" do
    patch edit_password_reset_path("bogus-token"), params: {
      user: { password: "hunter2", password_confirmation: "hunter2" }
    }

    assert_redirected_to forgot_password_path
    assert_match "invalid or has expired", flash[:alert]
  end

  test "token cannot be reused after password is updated" do
    token = @user.password_reset_token
    patch edit_password_reset_path(token), params: {
      user: { password: "firstnew", password_confirmation: "firstnew" }
    }

    patch edit_password_reset_path(token), params: {
      user: { password: "secondnew", password_confirmation: "secondnew" }
    }

    assert_redirected_to forgot_password_path
    assert @user.reload.authenticate("firstnew"), "Second use of token should not change password"
  end
end
