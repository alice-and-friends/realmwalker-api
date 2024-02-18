# frozen_string_literal: true

class RealmLocation < ApplicationRecord
  include ComfyCoordinates
  PLAYER_VISION_RADIUS = 10_000 # meters

  belongs_to :real_world_location
  has_one :inventory, dependent: :destroy

  validates :real_world_location_id, uniqueness: true
  validates :region, presence: true

  before_validation :set_region_and_coordinates!
  validates_associated :real_world_location

  delegate :inventory_items, to: :inventory

  scope :player_vision_radius, lambda { |geolocation|
    near(geolocation[:latitude], geolocation[:longitude], PLAYER_VISION_RADIUS)
  }

  private

  def set_region_and_coordinates!
    self.region = real_world_location.region if real_world_location.present?
    self.coordinates = real_world_location.coordinates if real_world_location.present?
  end
end
