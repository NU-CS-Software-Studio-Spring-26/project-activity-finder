class Activity < ApplicationRecord
  TITLE_MAX_LENGTH = 120
  CITY_MAX_LENGTH = 100
  CATEGORY_MAX_LENGTH = 80
  LOCATION_MAX_LENGTH = 200
  DESCRIPTION_MAX_LENGTH = 5_000

  belongs_to :user

  has_many :activity_signups, dependent: :destroy
  has_many :attendees, through: :activity_signups, source: :user

  validates :title, presence: true, length: { maximum: TITLE_MAX_LENGTH }
  validates :city, presence: true, length: { maximum: CITY_MAX_LENGTH }
  validates :category, presence: true, length: { maximum: CATEGORY_MAX_LENGTH }
  validates :location, length: { maximum: LOCATION_MAX_LENGTH }, allow_blank: true
  validates :description, length: { maximum: DESCRIPTION_MAX_LENGTH }, allow_blank: true
  validates :event_date, presence: true
  validates :capacity,
            numericality: { only_integer: true, greater_than: 0 },
            allow_nil: true

  has_many_attached :images
  validate :image_limit

  def ordered_images
    images.attachments.order(:position, :created_at)
  end

  def thumbnail
    ordered_images.first
  end

  def attendee_count
    activity_signups.count
  end

  def at_capacity?
    capacity.present? && attendee_count >= capacity
  end

  private
  def image_limit
    if images.attachments.length > 10
      errors.add(:images, "maximum is 10 images")
    end
  end
end
