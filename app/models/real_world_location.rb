# frozen_string_literal: true

class RealWorldLocation < ApplicationRecord
  self.inheritance_column = nil
  # validates :name, presence: true
  validates :type, presence: true
  validates :ext_id, uniqueness: true, allow_nil: true
  validates :coordinates, presence: true, uniqueness: true, coordinates: true
  scope :free, lambda {
    where.not(<<-SQL.squish
      EXISTS (SELECT 1 FROM dungeons WHERE dungeons.real_world_location_id = real_world_locations.id)
      OR EXISTS (SELECT 1 FROM battlefields WHERE battlefields.real_world_location_id = real_world_locations.id)
      OR EXISTS (SELECT 1 FROM npcs WHERE npcs.real_world_location_id = real_world_locations.id)
      OR EXISTS (SELECT 1 FROM bases WHERE bases.real_world_location_id = real_world_locations.id)
    SQL
    )
  }
  # scope :for_npc, -> { where(type: 'npc') }
  scope :for_dungeon, -> { where(type: 'unassigned') }

  scope :near, lambda { |latitude, longitude, distance|
    where("ST_DWithin(coordinates, 'POINT(#{longitude} #{latitude})', #{distance})")
  }

  scope :nearest, lambda { |latitude, longitude|
    order(Arel.sql(
      "ST_Distance(coordinates, ST_GeographyFromText('POINT(#{longitude.to_s} #{latitude.to_s})'))"
    )).first
  }

  def debug
    "https://www.google.com/maps/place/#{coordinates.lat},#{coordinates.lon} (cmd + double click)"
  end

  def self.ids_currently_in_use
    Dungeon.pluck(:real_world_location_id) +
      Battlefield.pluck(:real_world_location_id) +
      Npc.pluck(:real_world_location_id) +
      Base.pluck(:real_world_location_id)
  end
end
