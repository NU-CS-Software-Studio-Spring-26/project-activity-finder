module ActivityTextValidation
  extend ActiveSupport::Concern

  TITLE_MAX_LENGTH = 120
  TITLE_MIN_LENGTH = 3
  DESCRIPTION_MAX_LENGTH = 2_000
  LOCATION_MAX_LENGTH = 200

  TITLE_PATTERN = /\A[a-zA-Z0-9][a-zA-Z0-9\s.\-'&,!?():;\/+]*\z/
  DESCRIPTION_PATTERN = /\A[a-zA-Z0-9][a-zA-Z0-9\s.\-'&,!?():;\/+\n]*\z/
  LOCATION_PATTERN = /\A[a-zA-Z0-9][a-zA-Z0-9\s.,#'\-\/&():]*\z/
  SQL_LIKE_PATTERN = /
    \b(select|insert|update|delete|drop|union|alter|create|truncate)\b
    [\s\S]{0,80}?
    \b(from|into|table|database)\b
  /ix

  MIN_VOWEL_RATIO = 0.22
  LONG_TOKEN_MIN_LENGTH = 10
  LONG_TOKEN_MIN_VOWEL_RATIO = 0.28
  BIGRAM_CHECK_MIN_LENGTH = 8
  CONSONANT_CLUSTER_PATTERN = /[bcdfghjklmnpqrstvwxz]{5,}/i
  TOKEN_CONSONANT_CLUSTER_PATTERN = /[bcdfghjklmnpqrstvwxz]{4,}/i
  REPEATED_CHAR_PATTERN = /(.)\1{4,}/
  KEYBOARD_ROWS = %w[qwertyuiop asdfghjkl zxcvbnm].freeze
  TOKEN_SPLIT_PATTERN = /[\s,.;:!?\-\/&()]+/
  COMMON_BIGRAMS = %w[
    th he in er an re on at en nd ti es or te of ed is it
    al ar st to nt ng se ha as ou le me de co ne ri io ve
    ly ra ro li ce ea ch sh wh la ma na no us tr pr pl gr
    br fr fl bl cl gl sl sp sk sc sm sn sw ph gh ng mp ck
    ld lf lk lm lp lt ct pt rt rd rm rn rs ry cr dr el em
    et hi ho ic id ig il im ir iv ob oc od ol om op ot ov
    ow ub uc ud ul um un up ur ut ay ew oo ea ai ee
  ].freeze

  included do
    validates :title,
              presence: true,
              length: { minimum: TITLE_MIN_LENGTH, maximum: TITLE_MAX_LENGTH }
    validates :description,
              length: { maximum: DESCRIPTION_MAX_LENGTH },
              allow_blank: true
    validates :location,
              length: { maximum: LOCATION_MAX_LENGTH },
              allow_blank: true

    validate :title_text_rules
    validate :description_text_rules
    validate :location_text_rules

    before_validation :normalize_text_fields
  end

  class_methods do
    def gibberish_text?(text)
      return false if text.blank?

      return true if text.match?(REPEATED_CHAR_PATTERN)
      return true if keyboard_mash?(text)

      tokens = text.split(TOKEN_SPLIT_PATTERN).reject(&:blank?)
      tokens = [ text ] if tokens.empty?

      return true if tokens.any? { |token| gibberish_token?(token) }

      letters = text.gsub(/[^a-zA-Z]/, "")
      return false if letters.length < 5

      vowel_count = letters.scan(/[aeiouy]/i).length
      return true if vowel_count.zero?
      return true if vowel_count.to_f / letters.length < MIN_VOWEL_RATIO
      return true if text.match?(CONSONANT_CLUSTER_PATTERN)

      false
    end

    def gibberish_token?(token)
      token_letters = token.gsub(/[^a-zA-Z]/, "")
      return false if token_letters.length < TITLE_MIN_LENGTH
      return false if token_letters == token_letters.upcase

      token_vowels = token_letters.scan(/[aeiouy]/i).length
      return true if token_vowels.zero?

      vowel_ratio = token_vowels.to_f / token_letters.length

      if token_letters.length >= LONG_TOKEN_MIN_LENGTH && vowel_ratio < LONG_TOKEN_MIN_VOWEL_RATIO
        return true
      end

      if token_letters.length >= 6 && token.match?(CONSONANT_CLUSTER_PATTERN)
        return true
      end

      if token_letters.length >= 5 && token.match?(TOKEN_CONSONANT_CLUSTER_PATTERN) && vowel_ratio < 0.35
        return true
      end

      return true if lacks_common_bigrams?(token_letters)

      false
    end

    def lacks_common_bigrams?(token_letters)
      return false if token_letters.length < BIGRAM_CHECK_MIN_LENGTH

      lower = token_letters.downcase
      bigrams = (0...(lower.length - 1)).map { |index| lower[index, 2] }.select { |pair| pair.match?(/\A[a-z]{2}\z/) }
      return false if bigrams.empty?

      unique_common = bigrams.uniq.count { |pair| COMMON_BIGRAMS.include?(pair) }
      required = [ 3, token_letters.length / 4 ].max

      unique_common < required
    end

    def keyboard_mash?(text)
      downcased = text.downcase

      KEYBOARD_ROWS.any? do |row|
        (0..(row.length - 4)).any? do |index|
          sequence = row[index, 4]
          downcased.include?(sequence) || downcased.include?(sequence.reverse)
        end
      end
    end
  end

  private

  def normalize_text_fields
    self.title = squish_text(title)
    self.location = squish_text(location)
    self.description = normalize_description(description)
  end

  def squish_text(value)
    value.to_s.strip.gsub(/\s+/, " ").presence
  end

  def normalize_description(value)
    value.to_s.strip.gsub(/\r\n?/, "\n").presence
  end

  def title_text_rules
    return if title.blank?

    if title.match?(SQL_LIKE_PATTERN)
      errors.add(:title, "must be a readable activity name")
    elsif title.match?(/\A[\d\s\p{Punct}]+\z/u)
      errors.add(:title, "must include at least one letter")
    elsif !title.match?(TITLE_PATTERN)
      errors.add(:title, "contains unsupported characters")
    elsif self.class.gibberish_text?(title)
      errors.add(:title, "must be a readable activity name")
    end
  end

  def description_text_rules
    return if description.blank?

    if description.match?(SQL_LIKE_PATTERN)
      errors.add(:description, "contains unsupported content")
    elsif !description.match?(DESCRIPTION_PATTERN)
      errors.add(:description, "contains unsupported characters")
    elsif self.class.gibberish_text?(description)
      errors.add(:description, "must use readable words and sentences")
    end
  end

  def location_text_rules
    return if location.blank?

    if location.match?(SQL_LIKE_PATTERN)
      errors.add(:location, "must be a readable place or address")
    elsif !location.match?(LOCATION_PATTERN)
      errors.add(:location, "contains unsupported characters")
    elsif self.class.gibberish_text?(location)
      errors.add(:location, "must be a readable place or address")
    end
  end
end
