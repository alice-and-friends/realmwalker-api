require "test_helper"

class Api::V1::RealmLocationsControllerTest < ActionDispatch::IntegrationTest
  test "get list of realm locations" do
    get "/api/v1/realm_locations"
    assert_equal 200, status
    json = JSON.parse(response.body)
    assert_not json.empty?
  end
end
