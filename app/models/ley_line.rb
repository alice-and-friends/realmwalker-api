# frozen_string_literal: true

class LeyLine < RealmLocation
  include LocationStatus

  belongs_to :owner, class_name: 'User', optional: true
  alias_attribute :captured_by, :users

  validate :must_obey_minimum_distance
  validates :status, presence: true, inclusion: [
    statuses[:active],
    statuses[:expired],
  ]

  before_validation :set_region_and_coordinates!, on: :create

  def name
    'Ley line'
  end

  def captured?
    owner_id || captured_at
  end

  def captured!
    throw('Use captured_by! instead')
  end

  def captured_by!(user)
    throw('Already captured (you should check before calling this method)') if captured?

    LeyLine.transaction do
      Conquest.create!(realm_location: self, user: user)
      self.captured_at = Time.current if captured_at.nil? # captured_at should always be the FIRST time a location was captured
      save!
    end
  end

  private

  # Avoid placing ley lines too close to each other
  def must_obey_minimum_distance
    throw('Coordinates blank') if coordinates.blank?

    point = "ST_GeographyFromText('POINT(#{coordinates.longitude} #{coordinates.latitude})')"
    distance_query = Arel.sql("ST_Distance(coordinates::geography, #{point}) <= 700.0")

    exists_query = LeyLine.where(region: region)
                          .where.not(id: id)
                          .where(distance_query)
                          .exists?

    errors.add(:coordinates, 'Too close to other ley line') if exists_query
  end
end
