Feature: Password reset
  As a registered user
  I want to reset my password via email
  So that I can regain access to my account if I forget it

  Background:
    Given a user exists with email "reset-user@example.com" and password "oldpassword"

  # ---------------------------------------------------------------------------
  # Happy paths
  # ---------------------------------------------------------------------------

  Scenario: User requests a password reset email
    When I request a password reset for "reset-user@example.com"
    Then an email should be sent to "reset-user@example.com"
    And I should see "If that email is registered"

  Scenario: User opens a valid reset link
    When I request a password reset for "reset-user@example.com"
    And I open the password reset link from the email
    Then I should see "Choose a new password"

  Scenario: User resets their password successfully
    When I request a password reset for "reset-user@example.com"
    And I open the password reset link from the email
    And I submit a new password "newpassword" with confirmation "newpassword"
    Then I should be on the login page
    And I should see "Password updated"

  # ---------------------------------------------------------------------------
  # Sad paths
  # ---------------------------------------------------------------------------

  Scenario: Unknown email shows the same notice without sending an email
    When I request a password reset for "nobody@example.com"
    Then no email should be sent
    And I should see "If that email is registered"

  Scenario: Invalid reset token is rejected
    When I open a password reset link with an invalid token
    Then I should be on the forgot password page
    And I should see "invalid or has expired"

  Scenario: Mismatched password confirmation is rejected
    When I request a password reset for "reset-user@example.com"
    And I open the password reset link from the email
    And I submit a new password "newpassword" with confirmation "mismatch"
    Then I should see "doesn't match"
