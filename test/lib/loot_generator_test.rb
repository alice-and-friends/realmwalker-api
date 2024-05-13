# frozen_string_literal: true

require 'test_helper'

class LootGeneratorTest < ActiveSupport::TestCase
  test 'should generate loot container' do
    generator = LootGenerator.new
    generator.set_dungeon Dungeon.first
    generator.set_player User.first
    container = generator.generate_loot
    assert_instance_of LootContainer, container
    assert_instance_of Integer, container.gold
    assert_instance_of Array, container.items
  end
  test 'should include loot from dungeon inventory' do
    amulet_of_loss = Item.find_by(name: 'Amulet of Loss')
    raise 'test failure; could not find amulet of loss' if amulet_of_loss.nil?

    dungeon = Dungeon.create!(level: 1)

    # Add an item to the dungeon's inventory. This represents an item that a player has lost here (upon death)
    InventoryItem.create!(item: amulet_of_loss, inventory: dungeon.inventory)

    generator = LootGenerator.new
    generator.set_dungeon dungeon
    generator.set_player User.first
    container = generator.generate_loot

    # Ensure that the item has been moved to the loot container
    assert_includes container.items, amulet_of_loss
    assert_empty dungeon.inventory_items
  end
  test 'should always return an item' do
    dungeon = Dungeon.first

    # Ensure that our particular dungeon has droppable loot
    dungeon.monster.lootable_items << Item.last

    generator = LootGenerator.new
    generator.set_dungeon dungeon
    generator.set_player User.first

    3.times do
      result = generator.random_item(force: true)
      assert result.instance_of? Item
    end
  end
end
