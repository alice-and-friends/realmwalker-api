# frozen_string_literal: true

require 'test_helper'
require 'benchmark'

class DungeonTest < ActiveSupport::TestCase
  setup do
    diversify_dungeons
  end
  test 'there are dungeons in the test database' do
    assert_operator Dungeon.count, :>, 0
    assert_operator Dungeon.active.count, :>, 0
    assert_operator Dungeon.defeated.count, :>, 0
  end
  test 'can create random dungeon' do
    initial_count = Dungeon.count
    Dungeon.create!
    assert_operator Dungeon.count, :>, initial_count
  end
  test 'can create dungeons fast' do
    3.times do
      time = Benchmark.measure do
        Dungeon.create!
      end
      assert_operator time.real, :<=, 0.1
    end
  end
  test 'can create level 7 dungeon' do
    initial_count = Dungeon.count
    d = Dungeon.create!(level: 7)
    assert_operator Dungeon.count, :>, initial_count
    assert_equal 7, d.level
  end
  test 'dungeon gets hp from monster' do
    d = Dungeon.create!
    assert_equal d.monster.hp, d.hp
  end
  test 'validates presence of hp' do
    d = Dungeon.active.last
    d.hp = 0
    assert d.valid?
    d.hp = nil
    assert_not d.valid?
  end
  # test 'fresh player has 100% chance of defeating level 1 dungeon' do
  #   u = generate_test_user
  #   d = Dungeon.create!(level: 1)
  #   prediction = d.battle_prediction_for u
  #   assert_equal 100, prediction[:chance_of_success]
  # end
  # test 'fresh player character always defeats level 1 dungeon' do
  #   5.times do
  #     u = generate_test_user
  #     d = Dungeon.create!(level: 1)
  #     battle = d.battle_as(u)
  #     assert battle[:battle_result][:user_won]
  #     assert_not battle[:battle_result][:user_died]
  #   end
  # end
  # test 'fresh player has <5% chance of defeating level 9 dungeon' do
  #   u = generate_test_user
  #   d = Dungeon.create!(level: 9)
  #   prediction = d.battle_prediction_for u
  #   assert_operator prediction[:chance_of_success], :<, 5
  # end
  # test 'fresh player character always loses battle at level 9 dungeon' do
  #   5.times do
  #     u = generate_test_user
  #     d = Dungeon.create!(level: 9)
  #     battle = d.battle_as(u)
  #     assert_not battle[:battle_result][:user_won]
  #   end
  # end
  test 'player gains experience from defeating monster' do
    u = generate_test_user
    u.gains_or_loses_xp 100_000
    d = Dungeon.create!(level: 1)
    d.battle_as(u)
    assert_equal 100_000 + d.monster.xp, u.xp
  end
  test 'player gains gold and items from defeating monster' do
    5.times do
      u = generate_test_user.reload
      u.gains_or_loses_xp User::MAX_XP
      items_before_battle = u.inventory_items.count
      gold_before_battle = u.gold
      d = Dungeon.create!(level: 3)
      battle_data = d.battle_as(u)
      if battle_data[:battle_result][:user_won] && battle_data[:battle_result][:monster_died]
        assert_equal (items_before_battle + battle_data[:inventory_changes][:loot].items.length), u.inventory_items.count
        assert_equal (gold_before_battle + battle_data[:inventory_changes][:loot].gold), u.reload.gold
      end
    end
  end
  test 'two players can defeat the same dungeon' do
    dungeon = Dungeon.create!(level: 1)
    users = [
      generate_test_user,
      generate_test_user,
    ]
    users.each do |user|
      dungeon.battle_as(user)
    end
    assert_equal users.pluck(:id).sort, dungeon.defeated_by.pluck(:id).sort
  end
  test 'test environment dungeon always uses Europe/Oslo timezone' do
    new_dungeon = Dungeon.create!
    assert_equal 'Europe/Oslo', new_dungeon.timezone
    assert_not_nil new_dungeon.approximate_local_time
  end
end
