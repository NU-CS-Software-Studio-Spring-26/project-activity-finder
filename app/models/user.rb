class User < ApplicationRecord
  has_secure_password validations: false

  generates_token_for :password_reset, expires_in: 15.minutes do
    password_salt&.last(10)
  end

  has_one_attached :avatar

  has_many :activities, dependent: :destroy
  has_many :activity_signups, dependent: :destroy
  has_many :joined_activities, through: :activity_signups, source: :activity

  before_validation :normalize_email

  validate :acceptable_avatar

  validates :name, presence: true

  validates :email,
            presence: true,
            uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }

  validates :password, presence: true, confirmation: true, length: { minimum: 5 },
            on: :create,
            if: -> { provider.blank? }

  validates :password, confirmation: true, allow_blank: true, length: { minimum: 5 },
            if: -> { password.present? }

  def avatar_initial
    name.to_s.strip.first&.upcase || "U"
  end

  def password_reset_token
    generate_token_for(:password_reset)
  end

  # Returns [user, :new] when a User row was created, or [user, :returning] for an existing account
  # (including email/password accounts linked to Google on first OAuth sign-in).
  def self.from_omniauth(auth)
    info = auth.info
    email = info.email.to_s.strip.downcase.presence
    raise ArgumentError, "Google did not return an email address" if email.blank?

    raw = auth.extra&.[]("raw_info") || auth.extra&.[](:raw_info)
    if raw.respond_to?(:[])
      ev = raw["email_verified"] if raw.respond_to?(:key?) && raw.key?("email_verified")
      ev = raw[:email_verified] if ev.nil? && raw.respond_to?(:key?) && raw.key?(:email_verified)
      raise ArgumentError, "Google email is not verified" if ev == false
    end

    user = find_by(provider: auth.provider, uid: auth.uid)
    return [ user, :returning ] if user

    if (existing = find_by(email: email))
      if existing.provider.blank? && existing.uid.blank?
        existing.update!(provider: auth.provider, uid: auth.uid)
        return [ existing, :returning ]
      end
      if existing.provider == auth.provider && existing.uid == auth.uid
        return [ existing, :returning ]
      end

      raise ArgumentError, "An account with this email already exists"
    end

    random = SecureRandom.hex(32)
    user = create!(
      provider: auth.provider,
      uid: auth.uid,
      email: email,
      name: info.name.presence || email.split("@").first,
      password: random,
      password_confirmation: random
    )
    [ user, :new ]
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase.presence
  end

  def acceptable_avatar
    return unless avatar.attached?

    unless avatar.content_type.in?(%w[image/jpeg image/png image/webp image/gif])
      errors.add(:avatar, "must be a JPEG, PNG, WebP, or GIF image")
    end

    if avatar.byte_size > 5.megabytes
      errors.add(:avatar, "must be smaller than 5 MB")
    end
  end
end
