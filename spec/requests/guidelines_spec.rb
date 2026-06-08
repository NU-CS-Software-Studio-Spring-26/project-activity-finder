require "rails_helper"

RSpec.describe "Community guidelines", type: :request do
  describe "GET /guidelines" do
    context "happy path: guest user" do
      it "renders the guidelines page with expected content" do
        get guidelines_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Community Guidelines")
        expect(response.body).to include("Be respectful")
      end
    end

    context "happy path: logged-in user" do
      let(:user) do
        User.create!(
          name: "Guidelines User",
          email: "guidelines@example.com",
          password: "password",
          password_confirmation: "password"
        )
      end

      before { post login_path, params: { email: user.email, password: "password" } }

      it "renders the guidelines page" do
        get guidelines_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Community Guidelines")
      end
    end
  end
end
