require "test_helper"

class DungeonTest < ActiveSupport::TestCase
  test "there are dungeons in the test database" do
    assert_operator Dungeon.count, :>, 0
  end
  test "can create random dungeon" do
    initial_count = Dungeon.count.freeze
    d = Dungeon.create!
    assert_operator Dungeon.count, :>, initial_count
  end
  test "can create level 7 dungeon" do
    initial_count = Dungeon.count.freeze
    d = Dungeon.create!(level: 7)
    assert_operator Dungeon.count, :>, initial_count
    assert_equal 7, d.level
  end
  test "player defeats monster and gains xp" do
    u = User.first
    d = Dungeon.create!
    d.battle_as(u)
    assert_equal d.monster.xp, u.xp
  end
end
