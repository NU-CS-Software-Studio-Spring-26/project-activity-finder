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
end
