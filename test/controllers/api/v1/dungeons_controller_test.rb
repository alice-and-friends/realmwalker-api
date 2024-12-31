# frozen_string_literal: true

require 'test_helper'

class Api::V1::DungeonsControllerTest < ActionDispatch::IntegrationTest
  test 'should get active dungeon' do
    d = Dungeon.active.first
    get "/api/v1/dungeons/#{d.id}", headers: generate_headers
    assert_equal 200, status
    assert_equal d.id, response.parsed_body['id']
  end
  test 'should get battle prediction' do
    d = Dungeon.create!(level: 1)
    get "/api/v1/dungeons/#{d.id}/analyze", headers: generate_headers
    assert_equal 200, status
    assert_instance_of Integer, response.parsed_body['chanceOfSuccess']
  end
  test 'should get xpLevelReport after battle' do
    d = Dungeon.create!(level: 1)
    post "/api/v1/dungeons/#{d.id}/battle", params: {}, headers: generate_headers
    assert_equal 200, status
    assert_not_nil response.parsed_body['xpLevelReport']
  end
  test 'should get loot after battle' do
    User.first.give_starting_equipment # Give the api user starting equipment in order to avoid any penalties that may result in a loss
    d = Dungeon.create!(level: 1)
    post "/api/v1/dungeons/#{d.id}/battle", params: {}, headers: generate_headers
    assert_equal 200, status
    assert_not_nil response.parsed_body['inventoryChanges']['loot']
    assert_instance_of Integer, response.parsed_body['inventoryChanges']['loot']['gold']
    assert_instance_of Array, response.parsed_body['inventoryChanges']['loot']['items']
  end
  test 'should get defeated dungeon' do
    dungeon = Dungeon.active.first
    user = generate_test_user
    dungeon.defeated_by!(user)
    get "/api/v1/dungeons/#{dungeon.id}", headers: generate_headers

    # Test that we can see the dungeon has been defeated by someone(s)
    assert_equal 200, status
    assert_equal dungeon.id, response.parsed_body['id']
    assert_not_empty response.parsed_body['defeatedBy']

    # Test the information we get about the user
    disclosed_user_info = response.parsed_body['defeatedBy'].first
    assert_equal user.name, disclosed_user_info['name']
    assert_safe_user_object disclosed_user_info
  end
  test 'should get distance to dungeon' do
    dungeon = Dungeon.first
    test_user_location = generate_test_user_location
    distance_expected = test_user_location.distance(dungeon.coordinates)
    get "/api/v1/dungeons/#{dungeon.id}", headers: generate_headers
    assert_equal distance_expected, response.parsed_body['distanceFromUser']
  end
  test 'should not be allowed to search active dungeon' do
    dungeon = Dungeon.create!(level: 1)
    post "/api/v1/dungeons/#{dungeon.id}/search", params: {}, headers: generate_headers
    assert_includes 400..499, status # Should indicate a client error
    assert_nil response.parsed_body['loot']
    assert response.parsed_body['error']
    assert_not_nil response.parsed_body['message']
  end
  test 'should search defeated dungeon' do
    dungeon = Dungeon.create!(level: 1)
    dungeon.defeated_by! User.first
    post "/api/v1/dungeons/#{dungeon.id}/search", params: {}, headers: generate_headers
    assert_equal 200, status
    assert_not_nil response.parsed_body['loot']
  end
end
