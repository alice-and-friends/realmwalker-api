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
    where("ST_Distance(location,
                           "+"'POINT(#{latitude} #{longitude})') < #{distance}")}

  scope :nearest, lambda { |latitude, longitude, distance|
    where("ST_Distance(location,
                           "+"'POINT(#{latitude} #{longitude})') < #{distance}")
      .order("ST_Distance(coordinates, ST_GeographyFromText('POINT(#{latitude} #{longitude})'))").limit(1)}

  # def self.for(model)
  #   case model.name
  #   when 'Npc'
  #     free.for_npc.sample
  #   when 'Dungeon'
  #     free.for_dungeon.sample
  #   else
  #     throw('NOT IMPLEMENTED')
  #   end
  # end

  # Find the nearest unused location to a set of coordinates. Useful for spawning an NPC close to a player.
  def self.unused_near(latitude, longitude)
    free.order(Arel.sql(
      "ST_Distance(coordinates, ST_GeographyFromText('POINT(#{latitude.to_s} #{longitude.to_s})'))"
    )).first
  end

  def self.ids_currently_in_use
    Dungeon.pluck(:real_world_location_id) +
      Battlefield.pluck(:real_world_location_id) +
      Npc.pluck(:real_world_location_id) +
      Base.pluck(:real_world_location_id)
  end
end
