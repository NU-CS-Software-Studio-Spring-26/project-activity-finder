class Activity < ApplicationRecord
  include ActivityTextValidation

  CUSTOM_CATEGORY = "__custom__"
  VISIBILITY_OPTIONS = %w[public private].freeze

  ALLOWED_CITIES = [
    "Chicago",
    "Madison",
    "Milwaukee",
    "Minneapolis",
    "Detroit",
    "Indianapolis",
    "Columbus",
    "Cleveland",
    "St. Louis",
    "Kansas City",
    "Denver",
    "Seattle",
    "Portland",
    "San Francisco",
    "Los Angeles",
    "San Diego",
    "Phoenix",
    "Dallas",
    "Houston",
    "Austin",
    "Atlanta",
    "Miami",
    "Boston",
    "New York",
    "Philadelphia",
    "Washington"
  ].freeze

  CATEGORIES = [
    "Hike",
    "Food Crawl",
    "Coffee Meetup",
    "Trivia Night",
    "Art Walk",
    "Fitness Class",
    "Farmers Market",
    "Sports & Recreation",
    "Music & Live Events",
    "Workshop / Class",
    "Social & Networking",
    "Volunteer"
  ].freeze

  belongs_to :user

  has_many :activity_signups, dependent: :destroy
  has_many :attendees, through: :activity_signups, source: :user

  scope :publicly_visible, -> { where(visibility: "public") }

  validates :city, presence: true, inclusion: { in: ALLOWED_CITIES, message: "must be a supported city" }
  validates :category, presence: true
  validates :visibility, inclusion: { in: VISIBILITY_OPTIONS }
  before_validation :normalize_category
  before_validation :normalize_city
  before_create :generate_share_token
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

  def self.category_options
    CATEGORIES
  end

  def self.allowed_cities
    ALLOWED_CITIES
  end

  def preset_category?
    category.present? && CATEGORIES.include?(category)
  end

  def private?
    visibility == "private"
  end

  def public?
    visibility == "public"
  end

  private

  def normalize_category
    self.category = category.to_s.strip.presence
  end

  def normalize_city
    self.city = city.to_s.strip.presence
  end

  def generate_share_token
    self.share_token = loop do
      token = SecureRandom.urlsafe_base64(16)
      break token unless Activity.exists?(share_token: token)
    end
  end

  def image_limit
    if images.attachments.length > 10
      errors.add(:images, "maximum is 10 images")
    end
  end
end
