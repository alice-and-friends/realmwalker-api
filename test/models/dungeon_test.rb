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
  test 'player defeats monster and gains xp' do
    u = generate_test_user
    d = Dungeon.create!(level: 1)
    d.battle_as(u)
    assert_equal d.monster.xp, u.xp
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
  test 'fresh player character always dies at level 9 dungeon' do
    5.times do
      u = generate_test_user
      d = Dungeon.create!(level: 9)
      battle = d.battle_as(u)
      assert_not battle[:battle_result][:user_won]
      assert battle[:battle_result][:user_died]
    end
  end
end
