require "rails_helper"

RSpec.describe "Welcome page", type: :request do
  describe "GET /" do
    context "happy path: guest user" do
      it "renders the welcome page with the expected heading" do
        get root_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("What are you doing this weekend?")
      end
    end

    context "sad path: logged-in user" do
      let(:user) do
        User.create!(
          name: "Test User",
          email: "pages-test@example.com",
          password: "password",
          password_confirmation: "password"
        )
      end

      before { post login_path, params: { email: user.email, password: "password" } }

      it "redirects to the activities index" do
        get root_path

        expect(response).to redirect_to(activities_path)
      end
    end
  end
end
