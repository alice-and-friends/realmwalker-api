# frozen_string_literal: true

class LeyLine < RealmLocation
  # enum status: { active: 1, expired: 0 } # TODO: Define statuses in RealmLocation, and have validation here
  # store :properties, accessors: [ :level, :defeated_at, :defeated_by ], coder: JSON
  validate :minimum_distance
  before_validation :set_region_and_coordinates!, on: :create

  def name
    'Ley line'
  end

  private

  # Avoid placing ley lines too close to each other
  def minimum_distance
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
