Given("a public activity {string} hosted by {string} in {string}") do |title, host_email, city|
  host = find_user!(host_email)
  Activity.create!(
    title: title,
    city: city,
    category: "Hike",
    event_date: Date.current + 1,
    user: host,
    visibility: "public"
  )
end

Given("the activity {string} has a capacity of {int}") do |title, capacity|
  find_activity!(title).update!(capacity: capacity)
end

Given("{string} has joined the activity {string}") do |email, title|
  ActivitySignup.create!(activity: find_activity!(title), user: find_user!(email))
end

When("I create an activity titled {string} in {string}") do |title, city|
  post_activity(title: title, city: city)
  follow_redirect_if_present
end

When("I try to create an activity titled {string} in {string}") do |title, city|
  post_activity(title: title, city: city)
end

When("I join the activity {string}") do |title|
  activity = find_activity!(title)
  visit activity_path(activity)

  if page.has_button?("Join activity")
    click_button "Join activity"
  else
    # Full activities show a disabled label instead of a join button; POST like the controller test.
    page.driver.post join_activity_path(activity)
    follow_redirect_if_present
  end
end

Then("an activity titled {string} should exist in {string}") do |title, city|
  activity = Activity.find_by(title: title)
  expect(activity).to be_present
  expect(activity.city).to eq(city)
end

Then("an activity titled {string} should not exist") do |title|
  expect(Activity.find_by(title: title)).to be_nil
end

Then("I should see a validation error about inappropriate language") do
  expect(page.driver.response.body).to include("inappropriate language")
end

Then("{string} should be signed up for {string}") do |email, title|
  activity = find_activity!(title)
  user = find_user!(email)
  expect(ActivitySignup.exists?(activity: activity, user: user)).to be true
end

Then("{string} should not be signed up for {string}") do |email, title|
  activity = find_activity!(title)
  user = find_user!(email)
  expect(ActivitySignup.exists?(activity: activity, user: user)).to be false
end
