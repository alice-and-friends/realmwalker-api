require "test_helper"

class MonsterTest < ActiveSupport::TestCase
  test "user fixture loaded" do
    assert User.count == 1
  end
  test "no xp needed for level 1" do
    assert_equal User::total_xp_needed_for_level(1), 0
  end
  test "user starts with 0 xp at level 1" do
    u = User.first
    assert_equal u.xp, 0
    assert_equal u.level, 1
  end
  test "user levels up" do
    u = User.first

    u.gains_or_loses_xp(199)
    assert_equal u.xp, 199
    assert_equal u.level, 1

    u.gains_or_loses_xp(1)
    assert_equal u.xp, 200
    assert_equal u.level, 2

    u.gains_or_loses_xp(700)
    assert_equal u.xp, 900
    assert_equal u.level, 3

    assert_equal u.xp_level_report[:next_level_progress], 50.0
  end
  test "user can't exceed 1M xp / level 100" do
    u = User.first
    u.gains_or_loses_xp(999999999999999)
    assert_equal u.xp, 1000000
    assert_equal u.level, 100
  end
  test "user loses experience upon death" do
    u = User.first
    u.gains_or_loses_xp(User::total_xp_needed_for_level(50))
    assert_equal u.level, 50
    u.dies
    assert_equal u.level, 49
    assert u.xp < User::total_xp_needed_for_level(50)
  end
end
