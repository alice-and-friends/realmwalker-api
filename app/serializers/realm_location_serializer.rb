# frozen_string_literal: true

class RealmLocationSerializer < ActiveModel::Serializer
  attributes :id, :type, :level, :status, :name, :coordinates, :expires_at
  attribute :npc_details, if: :npc?
  attribute :distance_from_user, if: :user_location

  def coordinates
    {
      latitude: object.coordinates.latitude,
      longitude: object.coordinates.longitude,
    }
  end

  def dungeon?
    object.type == Dungeon.name
  end

  def npc?
    object.type == Npc.name
  end

  def npc_details
    {
      role: object.role,
      shop_type: object.shop_type,
      spooked: object.spooked?,
    }
  end

  def user_location
    instance_options[:seen_from]
  end

  def distance_from_user
    object.coordinates.distance(user_location)
  end
end
