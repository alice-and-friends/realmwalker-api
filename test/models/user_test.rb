require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "user fixture loaded" do
    assert User.count == 1
  end
  test "user receives starting equipment when created" do
    u = generate_test_user
    assert u.inventory_items.count > 0
  end
  test "can destroy user" do
    c = User.count
    u = generate_test_user
    u.destroy
    assert_equal c, User.count
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
  test "user cannot exceed equipment quotas" do
    # Prepare a user a bunch of items to use for the test
    u = User.first
    HELMET_1 = u.gain_item Item.find_by(type: 'helmet')
    HELMET_2 = u.gain_item Item.find_by(type: 'helmet')
    ARMOR_1 = u.gain_item Item.find_by(type: 'armor')
    ARMOR_2 = u.gain_item Item.find_by(type: 'armor')
    SHIELD_1 = u.gain_item Item.find_by(type: 'shield')
    SHIELD_2 = u.gain_item Item.find_by(type: 'shield')
    AMULET_1 = u.gain_item Item.find_by(type: 'amulet')
    AMULET_2 = u.gain_item Item.find_by(type: 'amulet')
    RING_1 = u.gain_item Item.find_by(type: 'ring')
    RING_2 = u.gain_item Item.find_by(type: 'ring')
    RING_3 = u.gain_item Item.find_by(type: 'ring')
    ONE_HANDED_WEAPON_1 = u.gain_item Item.find_by(type: 'weapon', two_handed: false)
    ONE_HANDED_WEAPON_2 = u.gain_item Item.find_by(type: 'weapon', two_handed: false)
    TWO_HANDED_WEAPON_1 = u.gain_item Item.find_by(type: 'weapon', two_handed: true)
    TWO_HANDED_WEAPON_2 = u.gain_item Item.find_by(type: 'weapon', two_handed: true)
    assert_equal 15, u.inventory_items.count

    # Test equipping a bunch of stuff - it should only be possible to equip one item of each type
    u.equip_item(HELMET_1, force=true)
    u.equip_item(HELMET_2, force=true)
    assert_equal 1, u.equipped_items.where('item.type': 'helmet').count

    u.equip_item(ARMOR_1, force=true)
    u.equip_item(ARMOR_2, force=true)
    assert_equal 1, u.equipped_items.where('item.type': 'armor').count,

    u.equip_item(SHIELD_1, force=true)
    u.equip_item(SHIELD_2, force=true)
    assert_equal 1, u.equipped_items.where('item.type': 'shield').count,

    u.equip_item(AMULET_1, force=true)
    u.equip_item(AMULET_2, force=true)
    assert_equal 1, u.equipped_items.where('item.type': 'amulet').count,

    u.equip_item(ONE_HANDED_WEAPON_1, force=true)
    u.equip_item(ONE_HANDED_WEAPON_2, force=true)
    assert_equal 1, u.equipped_items.where('item.type': 'weapon').count,

    # With rings, we allow equipping 2 rather than 1
    u.equip_item(RING_1, force=true)
    u.equip_item(RING_2, force=true)
    u.equip_item(RING_3, force=true)
    assert_equal 2, u.equipped_items.where('item.type': 'ring').count

    # Two handed weapons also work differently, in that you can't use them together with a shield
    u.equip_item(TWO_HANDED_WEAPON_1, force=true)
    assert_equal 0, u.equipped_items.where('item.type': 'shield').count # <- Shield should no longer be equipped
    u.equip_item(TWO_HANDED_WEAPON_2, force=true)
    assert_equal 1, u.equipped_items.where('item.type': 'weapon').count,
    u.equip_item(SHIELD_1, force=true)
    assert_equal 0, u.equipped_items.where('item.type': 'weapon').count # <- Weapon should no longer be equipped
  end
end
