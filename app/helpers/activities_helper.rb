module ActivitiesHelper
  NON_MAP_LOCATION_PATTERN = /\A(online|virtual|remote|zoom|teams|google\s*meet|webex|n\/a|tbd|none|—|-)\z/i.freeze

  POPULAR_ACTIVITY_CITIES = [
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

    asset_path("activity_finder_default_thumbnail.jpg")
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

    "default image"
  end
end
