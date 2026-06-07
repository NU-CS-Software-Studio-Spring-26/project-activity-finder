Feature: User registration
  As a new visitor
  I want to create an account
  So that I can host and join activities

  Scenario: Visitor registers with valid details
    When I register with name "Cucumber User" and email "cucumber-new@example.com" and password "password"
    Then I should see "Account created successfully"

  Scenario: Visitor cannot register with a duplicate email
    Given a user exists with email "cucumber-taken@example.com" and password "password"
    When I register with name "Duplicate User" and email "cucumber-taken@example.com" and password "password"
    Then I should see "Email has already been taken"
