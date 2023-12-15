# frozen_string_literal: true

class RealmLocation < ApplicationRecord
  self.abstract_class = true

  belongs_to :real_world_location
  validates_associated :real_world_location
  validates_uniqueness_of :real_world_location_id # TODO: Custom validator would be better. Not sure if this one even works?

  PLAYER_VISION_RADIUS = 25_000 # meters
  scope :player_vision_radius, lambda { |geolocation|
    joins(:real_world_location)
      .where(
        "ST_DWithin(real_world_locations.coordinates::geography, :coordinates, #{PLAYER_VISION_RADIUS})",
        coordinates: RGeo::Geos.factory(srid: 0).point(geolocation[:lat], geolocation[:lon])
      )
  }

  delegate :coordinates, to: :real_world_location

  def self.real_world_location_ids_currently_in_use
    Dungeon.pluck(:real_world_location_id) +
      Battlefield.pluck(:real_world_location_id) +
      Npc.pluck(:real_world_location_id) +
      Base.pluck(:real_world_location_id)
  end

  delegate :coordinates, to: :real_world_location

  def location_type
    self.class.name
  end
end
