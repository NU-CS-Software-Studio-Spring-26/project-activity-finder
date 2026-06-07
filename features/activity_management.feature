Feature: Activity management
  As a signed-in user
  I want to create and join activities
  So that I can participate in local events

  Background:
    Given a user exists with email "cucumber-host@example.com" and password "password"
    And a user exists with email "cucumber-guest@example.com" and password "password"

  Scenario: User creates an activity with valid details
    Given I am logged in as "cucumber-host@example.com"
    When I create an activity titled "Sunset Walk" in "Seattle"
    Then I should see "Activity created successfully"
    And an activity titled "Sunset Walk" should exist in "Seattle"

  Scenario: User cannot create an activity with profanity in the title
    Given I am logged in as "cucumber-host@example.com"
    When I try to create an activity titled "What the fuck hike" in "Seattle"
    Then I should see a validation error about inappropriate language
    And an activity titled "What the fuck hike" should not exist

  Scenario: User joins another user's activity
    Given a public activity "Board Game Night" hosted by "cucumber-host@example.com" in "Seattle"
    And I am logged in as "cucumber-guest@example.com"
    When I join the activity "Board Game Night"
    Then I should see "You joined this activity"
    And "cucumber-guest@example.com" should be signed up for "Board Game Night"

  Scenario: User cannot join a full activity
    Given a user exists with email "cucumber-filler@example.com" and password "password"
    And a public activity "Limited Hike" hosted by "cucumber-host@example.com" in "Seattle"
    And the activity "Limited Hike" has a capacity of 1
    And "cucumber-filler@example.com" has joined the activity "Limited Hike"
    And I am logged in as "cucumber-guest@example.com"
    When I join the activity "Limited Hike"
    Then I should see "This activity is full"
    And "cucumber-guest@example.com" should not be signed up for "Limited Hike"
