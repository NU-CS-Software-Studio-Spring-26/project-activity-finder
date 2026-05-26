require "test_helper"

class LocationGeocoderTest < ActiveSupport::TestCase
  test "build_query combines location and city when city is not in location" do
    query = LocationGeocoder.send(:build_query, "123 Main St", "Chicago")

    assert_equal "123 Main St, Chicago", query
  end

  test "build_query uses location alone when city is already included" do
    query = LocationGeocoder.send(:build_query, "123 Main St, Chicago", "Chicago")

    assert_equal "123 Main St, Chicago", query
  end

  test "coordinates returns nil for blank location" do
    assert_nil LocationGeocoder.coordinates("", city: "Chicago")
  end
end
