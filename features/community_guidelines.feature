Feature: Community guidelines
  As a visitor
  I want to read community guidelines
  So that I understand expected behavior on the platform

  Scenario: Guest can view the community guidelines page
    When I visit the community guidelines page
    Then I should see "Community Guidelines"
    And I should see "Be respectful"

  Scenario: Guest can reach guidelines without logging in
    When I visit the community guidelines page
    Then I should not be on the login page
