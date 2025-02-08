# frozen_string_literal: true

require 'test_helper'

class InventoryTransactionTest < ActiveSupport::TestCase
  setup do
    @inventory1 = users(:jane_doe).inventory
    @inventory2 = users(:john_doe).inventory
    @item = Item.first
    @inventory_item = @inventory1.add @item # Jane Doe's inventory item
    @transaction = InventoryTransaction.create!(description: 'Test Transaction')
  end

  # === Validation Tests ===

  test 'should require a description' do
    @transaction.description = nil
    assert_not @transaction.valid?, 'Transaction is valid without a description'
  end

  test 'should be staged by default' do
    assert_equal InventoryTransaction.statuses[:staged], @transaction.status
  end

  # === Order Methods Tests ===

  test 'order_create_item should add an item to create_items' do
    assert_difference('@transaction.create_items.size', 1) do
      @transaction.order_create_item(@item, @inventory1)
    end
    entry = @transaction.create_items.last
    assert_equal @item.id, entry[:item_id]
    assert_equal @inventory1.id, entry[:destination_id]
  end

  test 'order_transfer_item should add an item to transfer_items' do
    assert_difference('@transaction.transfer_items.size', 1) do
      @transaction.order_transfer_item(@inventory_item, @inventory2)
    end
    entry = @transaction.transfer_items.last
    assert_equal @inventory_item.id, entry[:inventory_item_id]
    assert_equal @inventory2.id, entry[:destination_id]
  end

  test 'order_destroy_item should add an item to destroy_items' do
    assert_difference('@transaction.destroy_items.size', 1) do
      @transaction.order_destroy_item(@inventory_item)
    end
    entry = @transaction.destroy_items.last
    assert_equal @inventory_item.id, entry[:inventory_item_id]
    assert_equal @inventory1.id, entry[:source_id]
  end

  test 'order_add_gold should add a gold entry to add_gold' do
    assert_difference('@transaction.add_gold.size', 1) do
      @transaction.order_add_gold(100, @inventory1)
    end
    entry = @transaction.add_gold.last
    assert_equal 100, entry[:amount]
    assert_equal @inventory1.id, entry[:destination_id]
  end

  test 'order_transfer_gold should add a gold entry to transfer_gold' do
    assert_difference('@transaction.transfer_gold.size', 1) do
      @transaction.order_transfer_gold(50, @inventory1, @inventory2)
    end
    entry = @transaction.transfer_gold.last
    assert_equal 50, entry[:amount]
    assert_equal @inventory1.id, entry[:source_id]
    assert_equal @inventory2.id, entry[:destination_id]
  end

  test 'order_subtract_gold should add a gold entry to subtract_gold' do
    assert_difference('@transaction.subtract_gold.size', 1) do
      @transaction.order_subtract_gold(25, @inventory1)
    end
    entry = @transaction.subtract_gold.last
    assert_equal 25, entry[:amount]
    assert_equal @inventory1.id, entry[:source_id]
  end

  # === Apply Method Tests ===

  test 'apply should process create_items and complete the transaction' do
    assert_difference('@inventory1.inventory_items.size', 1) do
      @transaction.order_create_item(@item, @inventory1)
      assert @transaction.save_and_apply!, 'Transaction apply failed'
      assert_equal InventoryTransaction.statuses[:completed], @transaction.status
    end
  end

  test 'apply should process transfer_items and update inventory' do
    @transaction.order_transfer_item(@inventory_item, @inventory2)
    assert @transaction.save_and_apply!, 'Transaction apply failed'
    assert_equal InventoryTransaction.statuses[:completed], @transaction.status
    assert @inventory_item.reload.inventory_id == @inventory2.id, 'Inventory item was not transferred'
  end

  test 'apply should process destroy_items and remove inventory items' do
    @transaction.order_destroy_item(@inventory_item)
    assert @transaction.save_and_apply!, 'Transaction apply failed'
    assert_equal InventoryTransaction.statuses[:completed], @transaction.status
    assert_not InventoryItem.exists?(@inventory_item.id), 'Inventory item was not destroyed'
  end

  test 'apply should fail if an inventory is not found' do
    @transaction.order_create_item(@item, Inventory.new(id: 9999)) # Nonexistent inventory
    assert_not @transaction.save_and_apply!, 'Transaction apply should fail for nonexistent inventory'
    assert_equal InventoryTransaction.statuses[:failed], @transaction.status
  end

  test 'apply should handle insufficient gold in source inventory' do
    @transaction.order_transfer_gold(5000, @inventory1, @inventory2) # Assuming inventory1 has less than 5000 gold
    assert_not @transaction.save_and_apply!, 'Transaction apply should fail for insufficient gold'
    assert_equal InventoryTransaction.statuses[:failed], @transaction.status
  end

  test 'should complete trade between players' do
    @inventory2.update(gold: 500)
    @transaction.order_transfer_item(@inventory_item, @inventory2)
    @transaction.order_transfer_gold(100, @inventory2, @inventory1)
    assert @transaction.save_and_apply!
    assert_equal 100, @inventory1.reload.gold
    assert_equal @inventory2.id, @inventory_item.reload.inventory_id
  end

  test 'should abort trade between players and rollback item move' do
    @transaction.order_transfer_item(@inventory_item, @inventory2)
    @transaction.order_transfer_gold(100, @inventory2, @inventory1)
    assert_not @transaction.save_and_apply!
    assert_equal 0, @inventory1.reload.gold
    assert_equal 0, @inventory2.reload.gold
    assert_equal @inventory1.id, @inventory_item.reload.inventory_id
  end
end
