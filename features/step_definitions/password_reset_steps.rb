When("I request a password reset for {string}") do |email|
  ActionMailer::Base.deliveries.clear
  visit forgot_password_path
  fill_in "Email", with: email
  click_button "Send reset link"
  follow_redirect_if_present
end

Then("an email should be sent to {string}") do |email|
  expect(ActionMailer::Base.deliveries.size).to eq(1)
  expect(ActionMailer::Base.deliveries.last.to).to include(email)
end

Then("no email should be sent") do
  expect(ActionMailer::Base.deliveries.size).to eq(0)
end

When("I open the password reset link from the email") do
  mail = ActionMailer::Base.deliveries.last
  body = mail.body.parts.map(&:decoded).join
  token = body.match(%r{/password/reset/([^\s"'<]+)})[1]
  visit edit_password_reset_path(token)
end

When("I submit a new password {string} with confirmation {string}") do |password, confirmation|
  fill_in "New password", with: password
  fill_in "Confirm new password", with: confirmation
  click_button "Update password"
  follow_redirect_if_present
end

When("I open a password reset link with an invalid token") do
  visit edit_password_reset_path("invalid-token")
  follow_redirect_if_present
end

Then("I should be on the forgot password page") do
  expect(page).to have_current_path(forgot_password_path, ignore_query: true)
end
