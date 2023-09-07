# frozen_string_literal: true

require 'test_helper'

class Api::V1::InventoryControllerTest < ActionDispatch::IntegrationTest
  SET_EQUIPPED_PATH = '/api/v1/inventory/set_equipped'
  test 'should return 404 when trying to equip non-existing item' do
    post SET_EQUIPPED_PATH, params: { item_id: 999, equipped: true }, headers: generate_headers
    assert_equal 404, status
  end

  test 'should equip and unequip item' do
    u = User.first
    WEAPON_1 = u.gain_item Item.find_by(type: 'weapon', two_handed: false)
    WEAPON_2 = u.gain_item Item.find_by(type: 'weapon', two_handed: false)

    # Equip a weapon
    post SET_EQUIPPED_PATH, params: {
      item_id: WEAPON_1.id,
      equipped: true,
    }, headers: generate_headers
    assert_equal 200, status
    assert InventoryItem.find(WEAPON_1.id).equipped?
    assert response.parsed_body['equipped']

    # Attempt to equip a second weapon, get a warning that the current weapon would be replaced
    post SET_EQUIPPED_PATH, params: {
      item_id: WEAPON_2.id,
      equipped: true,
    }, headers: generate_headers
    assert_equal 200, status
    assert_not InventoryItem.find(WEAPON_2.id).equipped?
    assert_not response.parsed_body['equipped']
    assert_equal 1, response.parsed_body['unequipItems'].length

    # Confirm weapon switch
    post SET_EQUIPPED_PATH, params: {
      item_id: WEAPON_2.id,
      equipped: true,
      force: true,
    }, headers: generate_headers
    assert_equal 200, status
    assert_not InventoryItem.find(WEAPON_1.id).equipped?
    assert InventoryItem.find(WEAPON_2.id).equipped?
    assert response.parsed_body['equipped']

    # Unequip
    post SET_EQUIPPED_PATH, params: {
      item_id: WEAPON_2.id,
      equipped: false,
    }, headers: generate_headers
    assert_equal 200, status
    assert_not InventoryItem.find(WEAPON_2.id).equipped?
  end
end
