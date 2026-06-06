module ActivitiesHelper
  NON_MAP_LOCATION_PATTERN = /\A(online|virtual|remote|zoom|teams|google\s*meet|webex|n\/a|tbd|none|—|-)\z/i.freeze

  CATEGORY_PLACEHOLDER_GRADIENTS = {
    "Hike"                 => %w[#1a3a2a #3a8c5c],
    "Food Crawl"           => %w[#3a1a1a #c4613a],
    "Coffee Meetup"        => %w[#2e1e10 #7a5230],
    "Trivia Night"         => %w[#1e1a3c #5040b4],
    "Art Walk"             => %w[#3a1a30 #b43a80],
    "Fitness Class"        => %w[#1a2a3a #3a88c4],
    "Farmers Market"       => %w[#1e3a10 #6ab440],
    "Sports & Recreation"  => %w[#1a2a3a #2a8ab4],
    "Music & Live Events"  => %w[#2a1a3a #8a3ac4],
    "Workshop / Class"     => %w[#2a2e1a #7a8a40],
    "Social & Networking"  => %w[#1a2030 #3a5ab4],
    "Volunteer"            => %w[#2e2a10 #b4901e],
  }.freeze

  POPULAR_ACTIVITY_CITIES = Activity::ALLOWED_CITIES

  EXTERNAL_ACTIVITY_IMAGE_FALLBACKS = [
    [ /sunrise ridge hike/i, "https://www.hikeoftheweek.com/wp-content/uploads/2016/07/DSC03218-scaled.jpg" ],
    [ /downtown taco/i, "https://www.statesmanjournal.com/gcdn/-mm-/ff08101970c9b392424972bf0f5861a9adca4d8f/c=0-110-2122-1304/local/-/media/2015/04/30/Salem/B9317155403Z.1_20150430164006_000_GEGALEEKJ.1-0.jpg?width=660&height=372&fit=crop&format=pjpg&auto=webp" ],
    [ /coffee.*code|code.*coffee/i, "https://www.chicagocodeandcoffee.com/images/4-dudes-exchanging-info-freeagency.webp" ],
    [ /campus trivi?a(l)? night/i, "https://news.gcu.edu/app/uploads/2022/01/TriviaNight-rf-012622-002-1.jpg" ],
    [ /art walk/i, "https://www.azcentral.com/gcdn/presto/2022/07/03/PPHX/adfc8dc7-643a-4bff-8d9f-de7114e9cb18-pb20220610_26173.JPG?width=700&height=467&fit=crop&format=pjpg&auto=webp" ],
    [ /\byoga\b/i, "https://images.squarespace-cdn.com/content/v1/62193ba47263892475701d45/1688456544945-29CE9S6E5YMQD0TJTHV2/Beginner%27s+yoga.jpg" ]
  ].freeze

  def activity_image(activity)
    return url_for(activity.thumbnail) if activity.thumbnail.present?

    external_fallback = EXTERNAL_ACTIVITY_IMAGE_FALLBACKS.find do |pattern, _url|
      activity.title.to_s.match?(pattern)
    end

    return external_fallback.last if external_fallback.present?

    category_placeholder_image(activity.category.to_s)
  end

  def activity_link_params(return_to: nil)
    return {} if return_to.blank?

    { from: "profile", return_to: return_to }
  end

  def activity_index_path(**query_params)
    if request.path == activities_path
      activities_path(query_params)
    else
      root_path(query_params)
    end
  end

  def activity_index_return_path(pagination:, city: nil, q: nil)
    query_params = { per_page: pagination[:per_page] }
    query_params[:page] = pagination[:page] if pagination[:page] > 1
    query_params[:city] = city if city.present?
    query_params[:q] = q if q.present?
    activity_index_path(**query_params)
  end

  def activity_show_path(activity, list_return_to: nil)
    url_params = list_return_to.present? ? { return_to: list_return_to } : {}
    activity_path(activity, **url_params)
  end

  # Links inside the home-page activities turbo frame must break out to a full
  # page visit; otherwise Turbo tries to render show inside the frame and fails.
  def activity_show_link_options(list_return_to: nil)
    { data: { turbo_frame: "_top" } }
  end

  def activity_location_map_showable?(activity)
    location = activity.location.to_s.strip
    return false if location.blank?
    return false if location.match?(NON_MAP_LOCATION_PATTERN)

    true
  end

  def activity_image_alt(activity)
    return activity.title.to_s if activity.thumbnail.present?

    external_fallback = EXTERNAL_ACTIVITY_IMAGE_FALLBACKS.find do |pattern, _url|
      activity.title.to_s.match?(pattern)
    end

    return activity.title.to_s if external_fallback.present?

    "#{activity.category} activity"
  end

  private

  def category_placeholder_image(category)
    colors = CATEGORY_PLACEHOLDER_GRADIENTS[category] || %w[#1a1e2e #3a4464]
    label  = ERB::Util.html_escape(category.presence || "Activity")
    svg = <<~SVG.strip
      <svg xmlns="http://www.w3.org/2000/svg" width="400" height="225">
        <defs>
          <linearGradient id="g" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stop-color="#{colors[0]}"/>
            <stop offset="100%" stop-color="#{colors[1]}"/>
          </linearGradient>
        </defs>
        <rect width="400" height="225" fill="url(#g)"/>
        <text x="200" y="113" text-anchor="middle" dominant-baseline="middle"
              font-family="system-ui,-apple-system,sans-serif"
              font-size="22" font-weight="600" fill="rgba(255,255,255,0.85)">#{label}</text>
      </svg>
    SVG
    "data:image/svg+xml;base64,#{[svg].pack('m0')}"
  end
end
