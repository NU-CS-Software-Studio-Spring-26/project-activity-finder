class User < ApplicationRecord
  has_secure_password

  has_many :activities, dependent: :destroy
  has_many :activity_signups, dependent: :destroy
  has_many :joined_activities, through: :activity_signups, source: :activity

  before_validation :normalize_email

  validates :name, presence: true

  validates :email,
            presence: true,
            uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }

  validates :password,
            length: { minimum: 5 },
            if: -> { password.present? }

  private

  def normalize_email
    self.email = email.to_s.strip.downcase.presence
  end
end
