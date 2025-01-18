# frozen_string_literal: true

require 'test_helper'

class DungeonSearchTest < ActiveSupport::TestCase
  setup do
    @user = generate_test_user
    @dungeon = Dungeon.create!(level: 1)
    @dungeon.defeated_by! @user
  end

  test 'destroying a user also destroys associated dungeon searches' do
    DungeonSearch.create!(user: @user, dungeon: @dungeon)

    assert_difference 'DungeonSearch.count', -1 do
      @user.destroy
    end
  end

  test 'destroying a dungeon also destroys associated dungeon searches' do
    DungeonSearch.create!(user: @user, dungeon: @dungeon)

    assert_difference 'DungeonSearch.count', -1 do
      @dungeon.destroy
    end
  end

  test 'should not allow duplicate dungeon searches for the same user' do
    DungeonSearch.create!(user: @user, dungeon: @dungeon)

    duplicate_search = DungeonSearch.new(user: @user, dungeon: @dungeon)
    assert_not duplicate_search.valid?
  end
end
