# frozen_string_literal: true

class RealmLocation < ApplicationRecord
  self.abstract_class = true

  belongs_to :real_world_location
  validates_associated :real_world_location
  validate :unique_real_world_location_id, on: :create
  validates :coordinates, presence: true, uniqueness: true, coordinates: true
  before_validation :set_real_world_location!, on: :create

  PLAYER_VISION_RADIUS = 10_000 # meters
  scope :player_vision_radius, lambda { |geolocation|
    where(
      "ST_DWithin(#{table_name}.coordinates::geography, :player_coordinates, #{PLAYER_VISION_RADIUS})",
      player_coordinates: RGeo::Geos.factory(srid: 0).point(geolocation[:lat], geolocation[:lon])
    )
  }

  def set_real_world_location!
    self.real_world_location = RealWorldLocation.free.sample if real_world_location_id.blank?
    self.coordinates = real_world_location.coordinates
  end

  def location_type
    self.class.name
  end

  private

  def unique_real_world_location_id
    return if real_world_location.nil?

    location_already_in_use = real_world_location.id.in? RealWorldLocation.ids_currently_in_use
    errors.add(:real_world_location, 'is already in use') if location_already_in_use
  end
end
