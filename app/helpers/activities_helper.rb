module ActivitiesHelper
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

  def activity_image_alt(activity)
    return activity.title.to_s if activity.thumbnail.present?

    external_fallback = EXTERNAL_ACTIVITY_IMAGE_FALLBACKS.find do |pattern, _url|
      activity.title.to_s.match?(pattern)
    end

    return activity.title.to_s if external_fallback.present?

    "default image"
  end
end
