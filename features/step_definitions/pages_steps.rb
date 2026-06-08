When("I visit the community guidelines page") do
  visit guidelines_path
end

Then("I should not be on the login page") do
  expect(page).not_to have_current_path(login_path, ignore_query: true)
end
