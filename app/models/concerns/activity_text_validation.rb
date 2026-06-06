module ActivityTextValidation
  extend ActiveSupport::Concern

  TITLE_MAX_LENGTH = 120
  TITLE_MIN_LENGTH = 3
  DESCRIPTION_MAX_LENGTH = 2_000
  LOCATION_MAX_LENGTH = 200

  TITLE_PATTERN = /\A[a-zA-Z0-9][a-zA-Z0-9\s.\-'&,!?():;\/+]*\z/
  LOCATION_PATTERN = /\A[a-zA-Z0-9][a-zA-Z0-9\s.,#'\-\/&():]*\z/
  SQL_LIKE_PATTERN = /
    \b(select|insert|update|delete|drop|union|alter|create|truncate)\b
    [\s\S]{0,80}?
    \b(from|into|table|database)\b
  /ix

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

  private

  def normalize_text_fields
    self.title = squish_text(title)
    self.location = squish_text(location)
    self.description = description.to_s.strip.presence
  end

  def squish_text(value)
    value.to_s.strip.gsub(/\s+/, " ").presence
  end

  def title_text_rules
    return if title.blank?

    if title.match?(SQL_LIKE_PATTERN)
      errors.add(:title, "must be a readable activity name")
    elsif title.match?(/\A[\d\s\p{Punct}]+\z/u)
      errors.add(:title, "must include at least one letter")
    elsif !title.match?(TITLE_PATTERN)
      errors.add(:title, "contains unsupported characters")
    end
  end

  def description_text_rules
    return if description.blank?

    if description.match?(SQL_LIKE_PATTERN)
      errors.add(:description, "contains unsupported content")
    end
  end

  def location_text_rules
    return if location.blank?

    if location.match?(SQL_LIKE_PATTERN)
      errors.add(:location, "must be a readable place or address")
    elsif !location.match?(LOCATION_PATTERN)
      errors.add(:location, "contains unsupported characters")
    end
  end
end
