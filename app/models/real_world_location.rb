# frozen_string_literal: true

class RealWorldLocation < ApplicationRecord
  include Coordinates

  self.inheritance_column = nil

  enum type: {
    ley_line: 'ley_line',
    runestone: 'runestone',
    shop: 'shop',
    unassigned: 'unassigned',
    user_owned: 'user_owned',
  }

  enum relevance_grade: { unseen: 0, seen: 1, inspected: 2, interacted: 3 }

  validates :type, presence: true
  validates :ext_id, uniqueness: true, allow_nil: true
  validate :must_obey_minimum_distance
  validates :region, presence: true, region: true

  before_validation :set_latitude_and_longitude!, on: :create

  scope :available, -> { where.not(id: RealmLocation.select(:real_world_location_id)) }
  scope :for_dungeon, -> { where(type: RealWorldLocation.types[:unassigned]) }
  scope :for_ley_line, -> { where(type: RealWorldLocation.types[:ley_line]) }
  scope :for_shop, -> { where(type: RealWorldLocation.types[:shop]) }
  scope :for_runestone, -> { where(type: RealWorldLocation.types[:runestone]) }

  def deterministic_rand(param)
    seed = Digest::SHA256.hexdigest("#{type}@#{ext_id}").to_i(16)
    prng = Random.new(seed)
    prng.rand(param)
  end

  def relevance_grade=(grade)
    throw('Not a valid grade') unless grade.in? RealWorldLocation.relevance_grades.values

    LocationRelevanceWorker.perform_async([id], grade)
  end

  def inspected!
    self.relevance_grade = RealWorldLocation.relevance_grades[:inspected]
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
