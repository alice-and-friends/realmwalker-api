# frozen_string_literal: true

require 'test_helper'

class BattleTest < ActiveSupport::TestCase
  test 'permanent record of battle' do
    user = generate_test_user
    dungeon = Dungeon.create!(level: 1)
    monster = dungeon.monster

    # Defeat the dungeon and check that the battle was recorded as a Conquest
    dungeon.defeated_by! user
    record = Battle.find_by(user: user, realm_location: dungeon, monster: dungeon.monster)
    assert_instance_of Battle, record

    # Destroy the dungeon and check that we still have a record
    dungeon.destroy!
    permanent_record = Battle.find_by(id: record.id)
    assert_instance_of Battle, record
    assert_equal user.id, permanent_record.user_id
    assert_equal monster.id, permanent_record.monster_id
  end
end
