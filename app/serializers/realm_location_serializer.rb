# frozen_string_literal: true

class RealmLocationSerializer < ActiveModel::Serializer
  attributes :id, :type, :level, :status, :name, :coordinates, :expires_at, :shop_type, :renewable_type, :role
  attribute :distance_from_user, if: :user_location
  attribute :spooked, if: :npc?

  def coordinates
    {
      latitude: object.coordinates.latitude,
      longitude: object.coordinates.longitude,
    }
  end

  def dungeon?
    object.type == Dungeon.name
  end

  def renewable?
    object.type == Renewable.name
  end

  def npc?
    object.type == Npc.name
  end

  def renewable_type
    object.sub_type if renewable?
  end

  def shop_type
    object.sub_type if npc?
  end

  def spooked
    object.spooked?
  end

  def user_location
    instance_options[:seen_from]
  end

  def distance_from_user
    object.coordinates.distance(user_location)
  end
end
