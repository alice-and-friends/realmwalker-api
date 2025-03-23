# frozen_string_literal: true

require 'test_helper'

class Api::V1::BattlesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @player = users(:jane_doe)
    @dungeon = Dungeon.create!(level: 1)
  end

  test 'should find or create battle' do
    battle_params = {
      battle: {
        opponent_id: @dungeon.id,
        opponent_type: @dungeon.class.name,
      },
    }

    # Start battle - Should create a new battle id
    post '/api/v1/battles', params: battle_params, headers: generate_headers
    assert_equal 201, status
    battle_id = response.parsed_body['battleId']
    assert_not_nil battle_id

    # Start battle (duplicate call) - Should return the previous battle id
    post '/api/v1/battles', params: battle_params, headers: generate_headers
    assert_equal 200, status
    assert_equal battle_id, response.parsed_body['battleId'] # Should return the same battle as for the previous call

    # Abandon the battle
    Battle.find(battle_id).battle_abandoned!

    # Start battle (duplicate call) - Should create a new battle id
    post '/api/v1/battles', params: battle_params, headers: generate_headers
    assert_equal 201, status
    assert_not_equal battle_id, response.parsed_body['battleId']
  end

  test 'should show battle with current turn' do
    @battle = Battle.create!(player: @player, opponent: @dungeon)
    get api_v1_battle_url(@battle), headers: generate_headers
    assert_response :success
    json = response.parsed_body

    # General
    assert_equal @battle.id, json['id']
    assert_equal Battle.statuses[:ongoing], json['status']

    # Participants
    assert json.key?('player'), 'Expected battle JSON to include player'
    assert_equal @player.name, json['player']['name']
    assert json.key?('opponent'), 'Expected battle JSON to include opponent'
    assert_equal @dungeon.name, json['opponent']['name']

    # Current turn
    assert json.key?('currentTurn'), 'Expected battle JSON to include currentTurn'
    assert_kind_of Integer, json['currentTurn']['sequence']
    assert_not_nil json['currentTurn']['actor']
    assert_not_nil json['currentTurn']['target']
    assert_not_nil json['currentTurn']['status']

    # Turn history
    assert_not_empty json['turns']
  end
end
