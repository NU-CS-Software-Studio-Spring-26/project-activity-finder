require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "should get guidelines page" do
    get guidelines_path
    assert_response :success
    assert_select "h1", "Community Guidelines"
  end
end
