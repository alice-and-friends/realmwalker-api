# frozen_string_literal: true

class RealmLocation < ApplicationRecord
  belongs_to :real_world_location
  validates_associated :real_world_location
  validates :real_world_location_id, uniqueness: true
  validates :coordinates, presence: true, uniqueness: true, coordinates: true
  before_validation :set_real_world_location!, on: :create

  has_one :inventory, dependent: :destroy
  delegate :inventory_items, to: :inventory

  PLAYER_VISION_RADIUS = 10_000 # meters
  scope :player_vision_radius, lambda { |geolocation|
    where(
      "ST_DWithin(#{table_name}.coordinates::geography, :player_coordinates, #{PLAYER_VISION_RADIUS})",
      player_coordinates: RGeo::Geos.factory(srid: 0).point(geolocation[:lon], geolocation[:lat])
    )
  }

  delegate :debug, to: :real_world_location

  def set_real_world_location!
    self.real_world_location = RealWorldLocation.free.sample if real_world_location_id.blank?
    self.coordinates = real_world_location.coordinates # Don't worry about this linter warning
  end

  def location_type
    self.class.name
  end
end
