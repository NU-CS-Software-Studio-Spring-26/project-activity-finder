Feature: User authentication
  As a visitor
  I want to sign in and out securely
  So that only authenticated users can manage activities

  Scenario: Guest can view the welcome page
    When I visit the home page
    Then I should see "What are you doing this weekend?"

  Scenario: Guest cannot browse activities without logging in
    When I try to visit the activities list
    Then I should be on the login page
    And I should see "You must be logged in"

  Scenario: User logs in with valid credentials
    Given a user exists with email "cucumber-login@example.com" and password "password"
    When I log in as "cucumber-login@example.com" with password "password"
    Then I should see "Logged in successfully"

  Scenario: User cannot log in with an invalid password
    Given a user exists with email "cucumber-bad@example.com" and password "password"
    When I log in as "cucumber-bad@example.com" with password "wrongpassword"
    Then I should see "Invalid email or password"

  Scenario: User logs out successfully
    Given a user exists with email "cucumber-logout@example.com" and password "password"
    And I am logged in as "cucumber-logout@example.com"
    When I log out
    Then I should see "Logged out successfully"
