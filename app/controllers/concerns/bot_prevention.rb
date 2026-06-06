# Lightweight, dependency-free bot prevention for public form submissions.
#
# Combines two classic server-side techniques that need no external service:
#
#   1. Honeypot field – a text input hidden from humans via CSS. Real users
#      never see or fill it, but many bots auto-fill every field, so any value
#      here is a strong bot signal.
#   2. Time trap – the form embeds a signed timestamp of when it was rendered.
#      Humans take a few seconds to fill a form; bots submit near-instantly.
#      A submission that arrives faster than MIN_FILL_SECONDS, slower than
#      MAX_FILL_SECONDS, or with a missing/tampered timestamp is treated as a bot.
#
# Include this in a controller and call `bot_submission?` before persisting a
# public record. Render the matching inputs with the
# `shared/bot_prevention_fields` partial inside the form.
module BotPrevention
  extend ActiveSupport::Concern

  # Innocuous-looking name so bots are tempted to fill it.
  HONEYPOT_FIELD = :contact_email_confirm
  TIMESTAMP_FIELD = :form_rendered_at

  # A human needs at least a couple of seconds to fill even a tiny form.
  MIN_FILL_SECONDS = 2
  # A token older than this is more likely replayed than a real, slow user.
  MAX_FILL_SECONDS = 1.day.to_i

  included do
    helper_method :bot_prevention_timestamp,
                  :bot_prevention_honeypot_field,
                  :bot_prevention_timestamp_field
  end

  private

  def bot_submission?
    honeypot_filled? || bad_submission_timing?
  end

  def honeypot_filled?
    params[HONEYPOT_FIELD].present?
  end

  def bad_submission_timing?
    rendered_at = verified_render_time
    return true if rendered_at.nil?

    elapsed = Time.current.to_f - rendered_at
    elapsed < MIN_FILL_SECONDS || elapsed > MAX_FILL_SECONDS
  end

  # Returns the render time (epoch float) only if the token is present and its
  # signature checks out; otherwise nil so the caller treats it as a bot.
  def verified_render_time
    token = params[TIMESTAMP_FIELD].to_s
    return if token.blank?

    bot_prevention_verifier.verify(token, purpose: :form_render_time).to_f
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    nil
  end

  # Signed so the client can't forge an older timestamp to beat the time trap.
  def bot_prevention_timestamp
    bot_prevention_verifier.generate(Time.current.to_f, purpose: :form_render_time)
  end

  def bot_prevention_honeypot_field
    HONEYPOT_FIELD
  end

  def bot_prevention_timestamp_field
    TIMESTAMP_FIELD
  end

  def bot_prevention_verifier
    Rails.application.message_verifier(:bot_prevention)
  end
end
