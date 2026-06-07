Given("a user exists with email {string} and password {string}") do |email, password|
  normalized = email.downcase
  create_user!(email: normalized, password: password) unless User.exists?(email: normalized)
end

Given("I am logged in as {string}") do |email|
  visit login_path
  fill_in "Email", with: email
  fill_in "Password", with: "password"
  click_button "Login"
end

When("I log in as {string} with password {string}") do |email, password|
  visit login_path
  fill_in "Email", with: email
  fill_in "Password", with: password
  click_button "Login"
end

When("I log out") do
  page.driver.delete logout_path
  follow_redirect_if_present
end

When("I visit the home page") do
  visit root_path
end

When("I try to visit the activities list") do
  visit activities_path
end

Then("I should be on the login page") do
  expect(page).to have_current_path(login_path, ignore_query: true)
end

Then("I should see {string}") do |text|
  expect(combined_page_content).to include(text)
end

When("I register with name {string} and email {string} and password {string}") do |name, email, password|
  post_registration(name: name, email: email, password: password)
  follow_redirect_if_present
end
