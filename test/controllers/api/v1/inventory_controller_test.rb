require "test_helper"

class Api::V1::InventoryControllerTest < ActionDispatch::IntegrationTest
  SET_EQUIPPED_PATH = "/api/v1/inventory/set_equipped"
  test "should return 404 when trying to equip non-existing item" do
    post SET_EQUIPPED_PATH, params: { item_id: 999,
                                              equipped: true }
    assert_equal 404, status
  end

  test "should equip and unequip item" do
    u = User.first
    WEAPON_1 = u.gain_item Item.find_by(type: 'weapon', two_handed: false)
    WEAPON_2 = u.gain_item Item.find_by(type: 'weapon', two_handed: false)

    # Equip a weapon
    post SET_EQUIPPED_PATH, params: {
      item_id: WEAPON_1.id,
      equipped: true,
    }
    assert_equal 200, status
    assert InventoryItem.find_by(id: WEAPON_1.id).is_equipped
    json = JSON.parse(response.body)
    assert json['equipped']

    # Attempt to equip a second weapon, get a warning that the current weapon would be replaced
    post SET_EQUIPPED_PATH, params: {
      item_id: WEAPON_2.id,
      equipped: true,
    }
    assert_equal 200, status
    assert_not InventoryItem.find_by(id: WEAPON_2.id).is_equipped
    json = JSON.parse(response.body)
    assert_not json['equipped']
    assert 1, json['unequipItems'].length

    # Confirm weapon switch
    post SET_EQUIPPED_PATH, params: {
      item_id: WEAPON_2.id,
      equipped: true,
      force: true,
    }
    assert_equal 200, status
    assert_not InventoryItem.find_by(id: WEAPON_1.id).is_equipped
    assert InventoryItem.find_by(id: WEAPON_2.id).is_equipped
    json = JSON.parse(response.body)
    assert json['equipped']

    # Unequip
    post SET_EQUIPPED_PATH, params: {
      item_id: WEAPON_2.id,
      equipped: false,
    }
    assert_equal 200, status
    assert_not InventoryItem.find_by(id: WEAPON_2.id).is_equipped
  end
end
