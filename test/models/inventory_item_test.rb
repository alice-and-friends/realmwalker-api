# frozen_string_literal: true

require 'test_helper'

class InventoryItemTest < ActiveSupport::TestCase
  test 'item is not equipped after being moved to different inventory' do
    user1 = generate_test_user
    user2 = generate_test_user
    inventory_item = user1.inventory_items.find_by(is_equipped: true)
    assert_not_nil inventory_item
    inventory_item.update!(inventory_id: user2.inventory.id)
    assert_not inventory_item.equipped?
  end
end
