# frozen_string_literal: true

class RealWorldLocation < ApplicationRecord
  include ComfyCoordinates
  self.inheritance_column = nil
  # validates :name, presence: true
  validates :type, presence: true
  validates :ext_id, uniqueness: true, allow_nil: true
  validate :minimum_distance

  scope :free, -> {
    where.not(id: RealmLocation.select(:real_world_location_id))
  }
  # scope :for_npc, -> { where(type: 'npc') }
  scope :for_dungeon, -> { where(type: 'unassigned') }

  private

  def minimum_distance
    throw('Coordinates blank') if coordinates.blank?

    point = "ST_GeographyFromText('POINT(#{coordinates.lon} #{coordinates.lat})')"
    distance_query = Arel.sql("ST_Distance(coordinates::geography, #{point}) <= 40.0")

    exists_query = RealWorldLocation.where(region: region)
                                    .where.not(id: id)
                                    .where(distance_query)
                                    .exists?

    errors.add(:coordinates, 'Too close to other location') if exists_query
  end
end
