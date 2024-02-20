# frozen_string_literal: true

class RealWorldLocation < ApplicationRecord
  include ComfyCoordinates

  self.inheritance_column = nil

  enum type: { shop: 'shop', ley_line: 'ley_line', user_owned: 'user_owned', unassigned: 'unassigned' }

  validates :type, presence: true
  validates :ext_id, uniqueness: true, allow_nil: true
  validate :minimum_distance

  before_validation :set_latitude_and_longitude!, on: :create

  scope :free, -> { where.not(id: RealmLocation.select(:real_world_location_id)) }
  scope :for_dungeon, -> { where(type: RealWorldLocation.types[:unassigned]) }

  private

  def set_latitude_and_longitude!
    throw('Coordinates blank') if coordinates.blank?

    return unless latitude.nil? || longitude.nil?

    self.latitude = coordinates.latitude
    self.longitude = coordinates.longitude
  end

  def minimum_distance
    throw('Coordinates blank') if coordinates.blank?

    point = "ST_GeographyFromText('POINT(#{coordinates.longitude} #{coordinates.latitude})')"
    distance_query = Arel.sql("ST_Distance(coordinates::geography, #{point}) <= 40.0")

    exists_query = RealWorldLocation.where(region: region)
                                    .where.not(id: id)
                                    .where(distance_query)
                                    .exists?

    errors.add(:coordinates, 'Too close to other location') if exists_query
  end
end
