require 'test_helper'

class DungeonTest < ActiveSupport::TestCase
  test 'there are dungeons in the test database' do
    assert_operator Dungeon.count, :>, 0
  end
  test 'can create random dungeon' do
    initial_count = Dungeon.count
    Dungeon.create!
    assert_operator Dungeon.count, :>, initial_count
  end
  test 'can create level 7 dungeon' do
    initial_count = Dungeon.count
    d = Dungeon.create!(level: 7)
    assert_operator Dungeon.count, :>, initial_count
    assert_equal 7, d.level
  end
  test 'fresh player has 100% chance of defeating level 1 dungeon' do
    u = generate_test_user
    d = Dungeon.create!(level: 1)
    prediction = d.battle_prediction_for u
    assert_equal 100, prediction[:chance_of_success]
  end
  test 'fresh player character always defeats level 1 dungeon' do
    5.times do
      u = generate_test_user
      d = Dungeon.create!(level: 1)
      battle = d.battle_as(u)
      assert battle[:battle_result][:user_won]
      assert_not battle[:battle_result][:user_died]
    end
  end
  test 'fresh player has 0% chance of defeating level 9 dungeon' do
    u = generate_test_user
    d = Dungeon.create!(level: 9)
    prediction = d.battle_prediction_for u
    assert_equal 0, prediction[:chance_of_success]
  end
  test 'fresh player character always loses battle at level 9 dungeon' do
    5.times do
      u = generate_test_user
      d = Dungeon.create!(level: 9)
      battle = d.battle_as(u)
      assert_not battle[:battle_result][:user_won]
    end
  end
  test 'player gains experience from defeating monster' do
    u = generate_test_user
    u.gains_or_loses_xp 100_000
    d = Dungeon.create!(level: 1)
    d.battle_as(u)
    assert_equal 100_000 + d.monster.xp, u.xp
  end
  test 'player gains gold+items from defeating monster' do
    5.times do
      u = generate_test_user
      u.gains_or_loses_xp User::MAX_XP
      items_before_battle = u.inventory_items.count
      gold_before_battle = u.gold
      d = Dungeon.create!(level: 3)
      battle_data = d.battle_as(u)
      if battle_data[:battle_result][:user_won] && battle_data[:battle_result][:monster_died]
        assert_equal (items_before_battle + battle_data[:inventory_changes][:loot].items.length), u.inventory_items.count
        assert_equal (gold_before_battle + battle_data[:inventory_changes][:loot].gold), u.gold
      end
    end
  end
end
