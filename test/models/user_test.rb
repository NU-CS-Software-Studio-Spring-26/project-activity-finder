require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = User.new(
      name: "Jason",
      email: "jason@example.com",
      password: "password",
      password_confirmation: "password"
    )
  end

  test "should be valid" do
    assert @user.valid?
  end

  test "name should be present" do
    @user.name = ""
    assert_not @user.valid?
  end

  test "email should be present" do
    @user.email = ""
    assert_not @user.valid?
  end

  test "email should be unique" do
    duplicate_user = @user.dup
    @user.save
    assert_not duplicate_user.valid?
  end

  test "email should be unique ignoring case" do
    @user.save!
    dup = @user.dup
    dup.email = @user.email.upcase
    assert_not dup.valid?
    assert dup.errors.of_kind?(:email, :taken)
  end

  test "password should be at least 5 characters" do
    @user.password = "1234"
    @user.password_confirmation = "1234"
    assert_not @user.valid?
  end

  test "name should not exceed maximum length" do
    @user.name = "a" * (User::NAME_MAX_LENGTH + 1)
    assert_not @user.valid?
    assert @user.errors.of_kind?(:name, :too_long)
  end

  test "email should not exceed maximum length" do
    local = "a" * (User::EMAIL_MAX_LENGTH - 11)
    @user.email = "#{local}@example.com"
    assert_not @user.valid?
    assert @user.errors.of_kind?(:email, :too_long)
  end

  test "from_omniauth creates user" do
    auth = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "uid-1",
      info: { email: "new_oauth@example.com", name: "OAuth User" },
      extra: { raw_info: { "email_verified" => true } }
    )
    assert_difference("User.count", 1) do
      _user, kind = User.from_omniauth(auth)
      assert_equal :new, kind
    end
    user = User.find_by!(email: "new_oauth@example.com")
    assert_equal "google_oauth2", user.provider
    assert_equal "uid-1", user.uid
  end

  test "from_omniauth links existing email/password account" do
    @user.save!
    auth = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "uid-2",
      info: { email: @user.email, name: @user.name },
      extra: { raw_info: { "email_verified" => true } }
    )
    assert_no_difference("User.count") do
      user, kind = User.from_omniauth(auth)
      assert_equal @user.id, user.id
      assert_equal :returning, kind
      assert_equal "google_oauth2", user.reload.provider
      assert_equal "uid-2", user.uid
    end
  end

  test "from_omniauth returns returning for existing google user" do
    auth = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "uid-return",
      info: { email: "returning_oauth@example.com", name: "Return User" },
      extra: { raw_info: { "email_verified" => true } }
    )
    User.from_omniauth(auth)
    _user, kind = User.from_omniauth(auth)
    assert_equal :returning, kind
  end
end
