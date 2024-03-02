# frozen_string_literal: true

class RealmLocationSerializer < ActiveModel::Serializer
  attributes :id, :type, :status, :name, :coordinates, :expires_at
  attribute :monster, if: :dungeon?
  attribute :npc_details, if: :npc?

  def coordinates
    {
      latitude: object.coordinates.latitude,
      longitude: object.coordinates.longitude,
      lat: object.coordinates.latitude, # DEPRECATED
      lon: object.coordinates.longitude, # DEPRECATED
    }
  end

  def dungeon?
    object.type == Dungeon.name
  end

  def npc?
    object.type == Npc.name
  end

  def monster
    ActiveModelSerializers::SerializableResource.new(object.monster, serializer: MonsterSerializer)
  end

  def npc_details
    {
      role: object.role,
      shop_type: object.shop_type,
      spooked: object.spooked?,
    }
  end
end
