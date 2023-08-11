require "test_helper"

class Api::V1::DungeonsControllerTest < ActionDispatch::IntegrationTest
  test "should get xpLevelReport after battle" do
    d = Dungeon.create!(level: 1)
    post "/api/v1/dungeons/#{d.id}/battle"
    assert_equal 200, status
    json = JSON.parse(response.body)
    assert_not_nil json['xpLevelReport']
  end
end
