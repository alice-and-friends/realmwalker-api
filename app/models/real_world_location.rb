# frozen_string_literal: true

class RealWorldLocation < ApplicationRecord
  include Coordinates

  self.inheritance_column = nil

  has_one :realm_location, dependent: :destroy

  enum type: {
    ley_line: 'ley_line',
    runestone: 'runestone',
    shop: 'shop',
    castle: 'castle',
    unassigned: 'unassigned',
    user_owned: 'user_owned',
  }

  enum relevance_grade: { unseen: 0, seen: 1, inspected: 2, interacted: 3, user_generated: 10 }

  validates :type, presence: true
  validates :ext_id, uniqueness: true, allow_nil: true
  validates :region, presence: true, region: true
  validate :must_obey_minimum_distance

  before_validation :set_latitude_and_longitude!, on: :create

  scope :available, -> { where.not(id: RealmLocation.select(:real_world_location_id).pluck(:real_world_location_id)) }
  scope :for_dungeon, -> { where(type: RealWorldLocation.types[:unassigned]) }
  scope :for_ley_line, -> { where(type: RealWorldLocation.types[:ley_line]) }
  scope :for_shop, -> { where(type: RealWorldLocation.types[:shop]) }
  scope :for_castle, -> { where(type: RealWorldLocation.types[:castle]) }
  scope :for_runestone, -> { where(type: RealWorldLocation.types[:runestone]) }

  def self.find_by_tag(tag_key, tag_value = nil)
    if tag_value.nil?
      # Return locations that have the tag_key with any value
      where("tags ? :key", key: tag_key)
    else
      # Return locations that have the tag_key with the specific tag_value
      where("tags ->> :key = :value", key: tag_key, value: tag_value)
    end
  end

  def tagged?(tag_key, tag_value = nil)
    if tag_value.nil?
      # Check if the tag_key exists
      tags.key?(tag_key.to_s)
    else
      # Check if the tag_key exists with the specific tag_value
      tags[tag_key.to_s] == tag_value
    end
  end

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
    raise('Coordinates blank') if coordinates.blank?

    return unless latitude.nil? || longitude.nil?

    self.latitude = coordinates.latitude
    self.longitude = coordinates.longitude
  end

  def must_obey_minimum_distance
    return if type == RealWorldLocation.types[:user_owned] # TODO: This might cause validation errors on nearby locations.
    # TODO, cont. Should probably disallow base creation near NPCS, and for other nearby entities, delete them?
    # TODO, cont. Also, a custom http code for "too close to object" might be nice.
    # TODO, cont. Also consider potential usability issues when two map markers overlap

    raise('Coordinates blank') if coordinates.blank?

    raise("Can't read longitude for rwl##{id}: #{coordinates.inspect}") unless coordinates.longitude

    point = "ST_GeographyFromText('POINT(#{coordinates.longitude} #{coordinates.latitude})')"
    distance_query = Arel.sql("ST_Distance(coordinates::geography, #{point}) <= 40.0")

    exists_query = RealWorldLocation.where(region: region)
                                    .where.not(id: id)
                                    .where.not(type: RealWorldLocation.types[:user_owned]) # TODO: Temporary fix to avoid validatione errors mentioned above
                                    .where(distance_query)
                                    .exists?

    errors.add(:coordinates, 'Too close to other location') if exists_query
  end
end
