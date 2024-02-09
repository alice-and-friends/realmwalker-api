# frozen_string_literal: true

class RealWorldLocation < ApplicationRecord
  self.inheritance_column = nil
  # validates :name, presence: true
  validates :type, presence: true
  validates :ext_id, uniqueness: true, allow_nil: true
  validates :coordinates, presence: true, coordinates: true
  scope :free, -> {
    where.not(id: RealmLocation.select(:real_world_location_id))
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

  def nearest_real_world_location
    throw('Coordinates blank') if coordinates.blank?

    point = "ST_GeographyFromText('POINT(#{coordinates.lon} #{coordinates.lat})')"
    distance_query = Arel.sql("ST_Distance(coordinates::geography, #{point})")

    rwl = RealWorldLocation.where.not(id: id)
                      .select("real_world_locations.id, #{distance_query}")
                      .order(distance_query)
                      .limit(1)

    [rwl, rwl.pick(distance_query)] if rwl.present?
  end
end
