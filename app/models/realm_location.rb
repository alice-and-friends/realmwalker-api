# frozen_string_literal: true

class RealmLocation < ApplicationRecord
  include Coordinates

  PLAYER_VISION_RADIUS = 10_000 # meters

  belongs_to :real_world_location
  has_one :inventory, dependent: :destroy
  has_many :conquests, dependent: :delete_all
  has_many :users, through: :conquests

  validates :real_world_location_id, uniqueness: true
  validates :region, presence: true, region: true

  before_validation :set_region_and_coordinates!
  validates_associated :real_world_location

  delegate :inventory_items, to: :inventory

  scope :scheduled_for_expiration, -> { where.not(expiry_job_id: nil) }

  scope :player_vision_radius, lambda { |geolocation|
    near(geolocation[:latitude], geolocation[:longitude], PLAYER_VISION_RADIUS)
  }

  private

  def set_region_and_coordinates!
    return if real_world_location.blank?

    self.region = real_world_location.region
    self.coordinates = real_world_location.coordinates
  end
end
