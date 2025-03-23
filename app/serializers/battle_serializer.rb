# frozen_string_literal: true

class BattleSerializer < ActiveModel::Serializer
  include BattleSerializerHelper

  attributes :id, :status, :created_at, :updated_at
  attribute :player
  attribute :opponent
  attribute :current_turn, if: :ongoing?
  attribute :turns

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
    ActiveModelSerializers::SerializableResource.new(object.current_turn, serializer: BattleTurnSerializer, user: current_user)
  end

  def turns
    ActiveModelSerializers::SerializableResource.new(object.turns, each_serializer: BattleTurnSerializer, user: current_user)
  end
end
