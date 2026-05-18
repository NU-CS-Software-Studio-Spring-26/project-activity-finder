class User < ApplicationRecord
  has_secure_password

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

  validates :password,
            length: { minimum: 5 },
            if: -> { password.present? }

  def avatar_initial
    name.to_s.strip.first&.upcase || "U"
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
