require 'test_helper'

class Api::V1::DungeonsControllerTest < ActionDispatch::IntegrationTest
  test 'should get battle prediction' do
    d = Dungeon.create!(level: 1)
    get "/api/v1/dungeons/#{d.id}/analyze"
    assert_equal 200, status
    assert_instance_of Integer, response.parsed_body['chanceOfSuccess']
  end
  test 'should get xpLevelReport after battle' do
    d = Dungeon.create!(level: 1)
    post "/api/v1/dungeons/#{d.id}/battle"
    assert_equal 200, status
    assert_not_nil response.parsed_body['xpLevelReport']
  end
end
