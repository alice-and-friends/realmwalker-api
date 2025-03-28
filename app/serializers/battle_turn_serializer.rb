# frozen_string_literal: true

class BattleTurnSerializer < ActiveModel::Serializer
  include BattleSerializerHelper

  attributes :id, :sequence, :status, :created_at, :updated_at
  attribute :actor
  attribute :target
  attribute :available_actions, if: :available_actions?

  def actor
    battle_participant_json(object.actor)
  end

  def target
    battle_participant_json(object.target)
  end

  def available_actions?
    object.turn_waiting_on_actor? && object.actor == current_user
  end

  def available_actions
    PlayerActionHelper.for_player(current_user)
  end
end
