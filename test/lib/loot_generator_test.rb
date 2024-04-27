# frozen_string_literal: true

require 'test_helper'

class LootGeneratorTest < ActiveSupport::TestCase
  test 'should generate loot container' do
    generator = LootGenerator.new(Dungeon.first, User.first)
    container = generator.generate_loot
    assert_instance_of LootContainer, container
    assert_instance_of Integer, container.gold
    assert_instance_of Array, container.items
  end
  test 'should include loot from dungeon inventory' do
    amulet_of_loss = Item.find_by(name: 'Amulet of Loss')
    raise 'test failure; could not find amulet of loss' if amulet_of_loss.nil?

    dungeon = Dungeon.create!(level: 1)
    InventoryItem.create!(item: amulet_of_loss, inventory: dungeon.inventory)

    generator = LootGenerator.new(dungeon, User.first)
    container = generator.generate_loot
    assert_includes container.items, amulet_of_loss
  end
end
