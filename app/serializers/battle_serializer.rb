# frozen_string_literal: true

class BattleSerializer < ActiveModel::Serializer
  include BattleSerializerHelper

  attributes :id, :status, :created_at, :updated_at
  attribute :player
  attribute :opponent
  attribute :current_turn, if: :ongoing?
  attribute :turns
  attribute :available_actions, if: :player_turn?
  attribute :next_step

  def ongoing?
    object.battle_ongoing?
  end

  def player
    battle_participant_json(object.player)
  end

  def opponent
    battle_participant_json(object.opponent)
  end

  def current_turn
    return if object.current_turn.blank?

    object.current_turn.with_lock do
      ActiveModelSerializers::SerializableResource.new(
        object.current_turn,
        serializer: BattleTurnSerializer,
        user: current_user,
      )
    end
  end

  def turns
    ActiveModelSerializers::SerializableResource.new(
      object.turns,
      each_serializer: BattleTurnSerializer,
      user: current_user,
    )
  end

  def available_actions
    @available_actions ||= PlayerActionHelper.for_player(current_user)
  end

  def next_step
    return 'concluded' if object.battle_completed? || object.battle_abandoned?

    if object.current_turn&.actor == current_user
      'your_turn'
    else
      'waiting'
    end
  end

  def player_turn?
    object.current_turn&.actor == current_user
  end
end
