# frozen_string_literal: true

require 'test_helper'

class BattleTurnTest < ActiveSupport::TestCase
  def setup
    @battle = Battle.create!(player: users(:jane_doe), opponent: Dungeon.active.first)
  end

  test 'battle_updated_at_changes_when_turn_is_created_or_updated' do
    turn = @battle.turns.last # Get the auto-generated turn from when battle was created

    # Reload the battle from DB and check if updated_at changed
    assert_equal turn.updated_at.to_f, @battle.reload.updated_at.to_f, 'Battle updated_at should match turn updated_at'

    turn.touch # Modify the turn

    # Reload the objects from DB and check if updated_at changed
    assert_equal turn.reload.updated_at.to_f, @battle.reload.updated_at.to_f, 'Battle updated_at should match turn updated_at'
  end

  test 'should not allow a new turn if previous turns are not completed' do
    new_turn = BattleTurn.new(battle: @battle, actor: users(:jane_doe), target: Dungeon.active.first)
    assert_not new_turn.valid?
    assert_includes new_turn.errors.full_messages, 'Cannot create new turn until the previous turn is completed'
  end
end
