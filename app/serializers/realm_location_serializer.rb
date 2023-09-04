# frozen_string_literal: true

class RealmLocationSerializer < ActiveModel::Serializer
  attributes :id, :location_type, :name, :coordinates
  attribute :dungeon_details, if: :dungeon?
  attribute :npc_details, if: :npc?

  def dungeon?
    object.location_type == Dungeon.name
  end

  def npc?
    object.location_type == Npc.name
  end

  def dungeon_details
    {
      level: object.level,
      monster_classification: object.monster.classification,
    }
  end

  def npc_details
    {
      role: object.role,
      shop_type: object.shop_type,
    }
  end
end
