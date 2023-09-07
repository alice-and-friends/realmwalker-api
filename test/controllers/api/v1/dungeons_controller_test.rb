# frozen_string_literal: true

require 'test_helper'

class Api::V1::DungeonsControllerTest < ActionDispatch::IntegrationTest
  test 'should get dungeon' do
    d = Dungeon.first
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
end
