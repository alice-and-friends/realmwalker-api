require "test_helper"

class DungeonTest < ActiveSupport::TestCase
  test "There are dungeons in the test database" do
    assert Dungeon.count > 0
  end
  test "can create dungeon" do
    initial_count = Dungeon.count.freeze
    d = Dungeon.create!
    assert Dungeon.count > initial_count
  end
  test "player defeats monster and gains xp" do
    u = User.first
    d = Dungeon.create!
    d.battle_as(u)
    assert_equal u.xp, d.monster.xp
  end
end
