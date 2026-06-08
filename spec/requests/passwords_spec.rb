require "rails_helper"

RSpec.describe "Password reset", type: :request do
  let(:user) do
    User.create!(
      name: "Grace",
      email: "grace@example.com",
      password: "oldpassword",
      password_confirmation: "oldpassword"
    )
  end

  before { ActionMailer::Base.deliveries.clear }

  # ---------------------------------------------------------------------------
  # GET /password/forgot
  # ---------------------------------------------------------------------------

  describe "GET /password/forgot" do
    it "renders the forgot-password form" do
      get forgot_password_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Reset your password")
    end

    it "redirects a logged-in user away" do
      post login_path, params: { email: user.email, password: "oldpassword" }

      get forgot_password_path

      expect(response).to redirect_to(root_path)
    end
  end

  # ---------------------------------------------------------------------------
  # POST /password/forgot
  # ---------------------------------------------------------------------------

  describe "POST /password/forgot" do
    context "happy path: registered email" do
      it "sends exactly one reset email to the user" do
        expect {
          post forgot_password_path, params: { email: user.email }
        }.to change { ActionMailer::Base.deliveries.size }.by(1)

        expect(ActionMailer::Base.deliveries.last.to).to include(user.email)
      end

      it "redirects to the login page with an ambiguous notice" do
        post forgot_password_path, params: { email: user.email }

        expect(response).to redirect_to(login_path)
        follow_redirect!
        expect(response.body).to include("If that email is registered")
      end
    end

    context "sad path: unknown email" do
      it "sends no email" do
        expect {
          post forgot_password_path, params: { email: "nobody@example.com" }
        }.not_to change { ActionMailer::Base.deliveries.size }
      end

      it "still redirects with the same ambiguous notice (no enumeration)" do
        post forgot_password_path, params: { email: "nobody@example.com" }

        expect(response).to redirect_to(login_path)
        follow_redirect!
        expect(response.body).to include("If that email is registered")
      end
    end
  end

  # ---------------------------------------------------------------------------
  # GET /password/reset/:token
  # ---------------------------------------------------------------------------

  describe "GET /password/reset/:token" do
    context "happy path: valid token" do
      it "renders the new-password form" do
        token = user.password_reset_token

        get edit_password_reset_path(token)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Choose a new password")
      end
    end

    context "sad path: invalid token" do
      it "redirects to the forgot-password page with an error flash" do
        get edit_password_reset_path("not-a-real-token")

        expect(response).to redirect_to(forgot_password_path)
        follow_redirect!
        expect(response.body).to include("invalid or has expired")
      end
    end

    context "sad path: token invalidated by a subsequent password change" do
      it "redirects to the forgot-password page" do
        token = user.password_reset_token
        user.update!(password: "changed", password_confirmation: "changed")

        get edit_password_reset_path(token)

        expect(response).to redirect_to(forgot_password_path)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # PATCH /password/reset/:token
  # ---------------------------------------------------------------------------

  describe "PATCH /password/reset/:token" do
    context "happy path: valid token and matching passwords" do
      it "updates the password and redirects to login with a success notice" do
        token = user.password_reset_token

        patch edit_password_reset_path(token), params: {
          user: { password: "newpassword", password_confirmation: "newpassword" }
        }

        expect(response).to redirect_to(login_path)
        follow_redirect!
        expect(response.body).to include("Password updated")
      end

      it "allows the user to log in with the new password" do
        token = user.password_reset_token
        patch edit_password_reset_path(token), params: {
          user: { password: "newpassword", password_confirmation: "newpassword" }
        }

        post login_path, params: { email: user.email, password: "newpassword" }

        expect(response).to redirect_to(root_path)
      end
    end

    context "sad path: mismatched password confirmation" do
      it "re-renders the form and leaves the original password unchanged" do
        token = user.password_reset_token

        patch edit_password_reset_path(token), params: {
          user: { password: "newpassword", password_confirmation: "mismatch" }
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(user.reload.authenticate("oldpassword")).to be_truthy
      end
    end

    context "sad path: invalid token" do
      it "redirects to the forgot-password page with an error flash" do
        patch edit_password_reset_path("bogus-token"), params: {
          user: { password: "newpassword", password_confirmation: "newpassword" }
        }

        expect(response).to redirect_to(forgot_password_path)
        follow_redirect!
        expect(response.body).to include("invalid or has expired")
      end
    end

    context "sad path: token cannot be reused after a successful reset" do
      it "rejects the second use and does not overwrite the already-reset password" do
        token = user.password_reset_token
        patch edit_password_reset_path(token), params: {
          user: { password: "firstnew", password_confirmation: "firstnew" }
        }

        patch edit_password_reset_path(token), params: {
          user: { password: "secondnew", password_confirmation: "secondnew" }
        }

        expect(response).to redirect_to(forgot_password_path)
        expect(user.reload.authenticate("firstnew")).to be_truthy
      end
    end
  end
end
