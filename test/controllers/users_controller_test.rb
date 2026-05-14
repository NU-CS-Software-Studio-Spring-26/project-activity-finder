require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @alice = User.create!(
      name: "Alice",
      email: "alice@example.com",
      password: "password",
      password_confirmation: "password"
    )
    @bob = User.create!(
      name: "Bob",
      email: "bob@example.com",
      password: "password",
      password_confirmation: "password"
    )
    post login_path, params: { email: @alice.email, password: "password" }
  end

  test "logged-in user can view another user's profile" do
    get user_url(@bob)
    assert_response :success
    assert_match @bob.name, response.body
  end

  test "cannot edit another user" do
    get edit_user_url(@bob)
    assert_redirected_to root_path
    follow_redirect!
    assert_match "Not authorized", response.body
  end

  test "cannot update another user" do
    patch user_url(@bob), params: {
      user: { name: "Hacked", email: @bob.email, password: "", password_confirmation: "" }
    }
    assert_redirected_to root_path
    @bob.reload
    assert_equal "Bob", @bob.name
  end

  test "cannot destroy another user" do
    assert_no_difference("User.count") do
      delete user_url(@bob)
    end
    assert_redirected_to root_path
  end

  test "admin can edit and destroy another user" do
    admin = User.create!(
      name: "Admin",
      email: "admin-user@example.com",
      password: "Admin",
      password_confirmation: "Admin",
      admin: true
    )
    post login_path, params: { email: admin.email, password: "Admin" }
    assert_redirected_to root_path

    get edit_user_url(@bob)
    assert_response :success

    assert_difference("User.count", -1) do
      delete user_url(@bob)
    end
    assert_redirected_to root_path
  end
end
