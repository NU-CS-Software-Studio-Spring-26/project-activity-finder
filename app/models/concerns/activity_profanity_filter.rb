module ActivityProfanityFilter
  extend ActiveSupport::Concern

  INAPPROPRIATE_LANGUAGE_MESSAGE = "contains inappropriate language"

  BLOCKED_TERMS = %w[
    asshole bastard bitch blowjob bullshit clit cock cunt damn dammit dick
    douche fag faggot fuck fucker fucking handjob hell hoe jackass jerkoff
    kys molest motherfucker nazi nigga nigger pedophile paedophile piss porn
    porno pornography pussy rapist rape raping retard shit slut tit tits twat
    whore wtf
  ].freeze

  BLOCKED_PHRASES = [
    "child porn",
    "child porno",
    "kill yourself"
  ].freeze

  BLOCKED_PATTERN = Regexp.new(
    '\b(?:' + BLOCKED_TERMS.map { |term| Regexp.escape(term) }.join("|") + ')\b',
    Regexp::IGNORECASE
  )

  class_methods do
    def profanity?(text)
      return false if text.blank?

      normalized = normalize_for_profanity_check(text)
      return true if normalized.match?(BLOCKED_PATTERN)
      return true if blocked_phrase?(normalized)

      false
    end

    def normalize_for_profanity_check(text)
      normalized = text.to_s.downcase
      normalized = normalized.tr("@", "a")
      normalized = normalized.tr("01345$!", "oielss")
      normalized = normalized.gsub(/[^a-z0-9\s]/, " ")
      normalized.gsub(/\s+/, " ").strip
    end

    def blocked_phrase?(normalized)
      BLOCKED_PHRASES.any? { |phrase| normalized.include?(phrase) }
    end
  end
end
