Feature: Welcome page
  As a visitor
  I want to view the welcome page
  So that I can learn about the application before signing up

  Scenario: Guest can view the welcome page
    When I visit the home page
    Then I should see "What are you doing this weekend?"

  Scenario: Logged-in user is redirected to the activities page
    Given a user exists with email "welcome-loggedin@example.com" and password "password"
    And I am logged in as "welcome-loggedin@example.com"
    When I visit the home page
    Then I should be on the activities page
