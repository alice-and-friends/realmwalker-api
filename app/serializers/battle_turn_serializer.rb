# frozen_string_literal: true

class BattleTurnSerializer < ActiveModel::Serializer
  include BattleSerializerHelper

  attributes :id, :sequence, :status, :created_at, :updated_at
  attribute :actor
  attribute :target

  def actor
    battle_participant_json(object.actor)
  end

  def target
    battle_participant_json(object.target)
  end
end
