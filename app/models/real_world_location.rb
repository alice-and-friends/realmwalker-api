# frozen_string_literal: true

class RealWorldLocation < ApplicationRecord
  include Coordinates

  self.inheritance_column = nil

  has_one :realm_location, dependent: :destroy

  enum type: {
    ley_line: 'ley_line',
    location: 'runestone',
    shop: 'shop',
    unassigned: 'unassigned',
    user_owned: 'user_owned',
  }

  enum relevance_grade: { unseen: 0, seen: 1, inspected: 2, interacted: 3, user_generated: 10 }

  validates :type, presence: true
  validates :ext_id, uniqueness: true, allow_nil: true
  validates :region, presence: true, region: true
  validate :must_obey_minimum_distance

  before_validation :set_latitude_and_longitude!, on: :create

  scope :available, -> { where.not(id: RealmLocation.select(:real_world_location_id)) }
  scope :for_dungeon, -> { where(type: RealWorldLocation.types[:unassigned]) }
  scope :for_ley_line, -> { where(type: RealWorldLocation.types[:ley_line]) }
  scope :for_shop, -> { where(type: RealWorldLocation.types[:shop]) }
  scope :for_runestone, -> { where(type: RealWorldLocation.types[:location]) }

  def deterministic_rand(param)
    seed = Digest::SHA256.hexdigest("#{type}@#{ext_id}").to_i(16)
    prng = Random.new(seed)
    prng.rand(param)
  end

  def relevance_grade=(new_value)
    throw('Not a valid relevance grade') unless new_value.in? RealWorldLocation.relevance_grades.values

    current_value = RealWorldLocation.relevance_grades[relevance_grade]
    throw('Relevance grade can only increase or stay the same') if new_value < current_value

    LocationRelevanceWorker.perform_async([id], new_value)
  end

  def inspected!
    current_value = RealWorldLocation.relevance_grades[relevance_grade]
    self.relevance_grade = RealWorldLocation.relevance_grades[:inspected] if current_value < RealWorldLocation.relevance_grades[:inspected]
  end

  private

  def set_latitude_and_longitude!
    throw('Coordinates blank') if coordinates.blank?

    return unless latitude.nil? || longitude.nil?

    self.latitude = coordinates.latitude
    self.longitude = coordinates.longitude
  end

  def must_obey_minimum_distance
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
