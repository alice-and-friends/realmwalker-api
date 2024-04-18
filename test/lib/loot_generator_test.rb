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
end
