# frozen_string_literal: true

require 'test_helper'

class Api::V1::InventoryItemControllerTest < ActionDispatch::IntegrationTest
  test 'store item to structure' do
    user = users(:jane_doe)
    inventory_item = user.gain_item Item.find_by(name: 'Leather Armor')
    user.equip_item(inventory_item, true)
    assert inventory_item.equipped?
    base = user.construct_base_at(generate_test_user_location)
    patch "/api/v1/inventory_items/#{inventory_item.id}", params: { inventory_item: { inventory_id: base.inventory.id } },
                                                          headers: generate_headers
    assert_equal 0, user.inventory_items.count
    assert_equal 1, base.inventory_items.count
  end
  # test 'pick up item from structure' do
  # end
end
