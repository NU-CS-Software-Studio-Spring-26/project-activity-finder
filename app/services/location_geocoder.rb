# frozen_string_literal: true

require "net/http"
require "json"

class LocationGeocoder
  BASE_URL = "https://nominatim.openstreetmap.org/search"
  USER_AGENT = "OpenSceneActivityFinder/1.0"

  def self.coordinates(location, city: nil)
    query = build_query(location, city)
    return nil if query.blank?

    uri = URI(BASE_URL)
    uri.query = URI.encode_www_form(q: query, format: "json", limit: 1)

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 5) do |http|
      request = Net::HTTP::Get.new(uri)
      request["User-Agent"] = USER_AGENT
      request["Accept"] = "application/json"
      http.request(request)
    end

    return nil unless response.is_a?(Net::HTTPSuccess)

    results = JSON.parse(response.body)
    return nil if results.blank?

    { lat: results.first["lat"].to_f, lon: results.first["lon"].to_f }
  rescue JSON::ParserError, Net::OpenTimeout, Net::ReadTimeout, SocketError
    nil
  end

  def self.build_query(location, city)
    location = location.to_s.strip
    city = city.to_s.strip
    return nil if location.blank?

    if city.present? && !location.downcase.include?(city.downcase)
      "#{location}, #{city}"
    else
      location
    end
  end
  private_class_method :build_query
end
