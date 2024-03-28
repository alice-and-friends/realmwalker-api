# frozen_string_literal: true

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test 'user fixtures loaded' do
    assert_operator User.count, :>, 0
  end
  test 'user receives starting equipment when created' do
    assert_not_empty generate_test_user.inventory_items
  end
  test 'new user starts with a small amount of gold' do
    u = generate_test_user
    assert_includes 1..100, u.gold
  end
  test 'user gains and loses gold' do
    u = generate_test_user
    starting_gold = u.gold
    u.gains_or_loses_gold(2)
    assert_equal starting_gold + 2, u.gold
    u.gains_or_loses_gold(-1)
    assert_equal starting_gold + 1, u.gold
  end
  test "user can't have less than 0 gold" do
    u = User.first
    u.gains_or_loses_gold(-999_999_999)
    assert_equal 0, u.gold
  end
  test 'can destroy user' do
    c = User.count
    u = generate_test_user
    u.destroy
    assert_equal c, User.count
  end
  test 'no xp needed for level 1' do
    assert_equal User.total_xp_needed_for_level(1), 0
  end
  test 'user starts with 0 xp at level 1' do
    u = User.first
    assert_equal 0, u.xp
    assert_equal 1, u.level
  end
  test 'user levels up' do
    u = User.first

    u.gains_or_loses_xp(199)
    assert_equal 199, u.xp
    assert_equal 1, u.level

    u.gains_or_loses_xp(1)
    assert_equal 200, u.xp
    assert_equal 2, u.level

    u.gains_or_loses_xp(700)
    assert_equal 900, u.xp
    assert_equal 3, u.level

    assert_equal u.xp_level_report[:next_level_progress], 50.0
  end
  test "user can't exceed 1M xp / level 100" do
    u = User.first
    u.gains_or_loses_xp(User::MAX_XP + 999_999_999)
    assert_equal User::MAX_XP, u.xp
    assert_equal 100, u.level
  end
  test "user can't have less than 0 xp / level 1" do
    u = User.first
    u.gains_or_loses_xp(-(User::MAX_XP + 999_999_999))
    assert_equal 0, u.xp
    assert_equal 1, u.level
  end
  test 'new user gains loot at standard rate' do
    assert_equal 0.0, generate_test_user.loot_bonus
  end
  test 'user has a loot bonus when wearing ring of treasure hunter' do
    u = generate_test_user
    u.equip_item u.gain_item Item.find_by(name: 'Ring of Treasure Hunter')
    assert u.loot_bonus.positive?
  end
  test 'new user gains xp at standard rate' do
    u = generate_test_user
    assert_equal 1, u.xp_multiplier
    u.gains_or_loses_xp 100
    assert_equal 100, u.xp
  end
  test 'user gains more xp when wearing amulet of abundance' do
    u = generate_test_user
    u.equip_item u.gain_item Item.find_by(name: 'Amulet of Abundance')
    assert_operator u.xp_multiplier, :>, 1.0
    u.gains_or_loses_xp 100
    assert_operator u.xp, :>, 100
  end
  test 'user cannot exceed equipment quotas' do
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
    u.equip_item(HELMET_1, true)
    u.equip_item(HELMET_2, true)
    assert_equal 1, u.equipped_items.where('item.type': 'helmet').count

    u.equip_item(ARMOR_1, true)
    u.equip_item(ARMOR_2, true)
    assert_equal 1, u.equipped_items.where('item.type': 'armor').count,

    u.equip_item(SHIELD_1, true)
    u.equip_item(SHIELD_2, true)
    assert_equal 1, u.equipped_items.where('item.type': 'shield').count,

    u.equip_item(AMULET_1, true)
    u.equip_item(AMULET_2, true)
    assert_equal 1, u.equipped_items.where('item.type': 'amulet').count,

    u.equip_item(ONE_HANDED_WEAPON_1, true)
    u.equip_item(ONE_HANDED_WEAPON_2, true)
    assert_equal 1, u.equipped_items.where('item.type': 'weapon').count,

    # With rings, we allow equipping 2 rather than 1
    u.equip_item(RING_1, true)
    u.equip_item(RING_2, true)
    u.equip_item(RING_3, true)
    assert_equal 2, u.equipped_items.where('item.type': 'ring').count

    # Two handed weapons also work differently, in that you can't use them together with a shield
    u.equip_item(TWO_HANDED_WEAPON_1, true)
    assert_equal 0, u.equipped_items.where('item.type': 'shield').count # <- Shield should no longer be equipped
    u.equip_item(TWO_HANDED_WEAPON_2, true)
    assert_equal 1, u.equipped_items.where('item.type': 'weapon').count,
    u.equip_item(SHIELD_1, true)
    assert_equal 0, u.equipped_items.where('item.type': 'weapon').count # <- Weapon should no longer be equipped
  end
  test 'user has higher defense bonus after equipping legendary shield' do
    u = generate_test_user
    orig_defense_bonus = u.defense_bonus
    shield = u.gain_item Item.find_by(type: 'shield', rarity: 'legendary')
    u.equip_item(shield, true)
    assert_operator u.defense_bonus, :>, orig_defense_bonus
  end
  test 'user loses experience upon death' do
    u = generate_test_user
    u.gains_or_loses_xp User.total_xp_needed_for_level(5)
    assert_equal 5, u.level
    u.handle_death
    assert_equal 4, u.level
    assert_operator u.xp, :<, User.total_xp_needed_for_level(5)
  end
  test 'user loses inventory upon death' do
    u = generate_test_user
    u.gain_item Item.first
    u.handle_death
    assert_equal 0, u.inventory_items.where(is_equipped: false).count
  end
  test 'user discovers runestones' do
    runestone = RunestonesHelper.first
    u = generate_test_user

    # Invalid runestone id
    assert_throws :invalid do
      u.discover_runestone('I do not exist')
    end

    # First discovery of valid runestone
    return_value = u.discover_runestone(runestone.id)
    assert return_value
    assert_equal 1, u.discovered_runestones.length

    # Re-discovery of the same stone
    return_value = u.discover_runestone(runestone.id)
    assert_not return_value
    assert_equal 1, u.discovered_runestones.length
  end
  test 'user has discovered runestone' do
    runestone = RunestonesHelper.first
    u = generate_test_user
    u.discover_runestone runestone.id
    assert u.discovered_runestone? runestone.id
  end
  test 'user has not discovered runestone' do
    runestone = RunestonesHelper.first
    u = generate_test_user
    assert_not u.discovered_runestone? runestone.id
  end
end
