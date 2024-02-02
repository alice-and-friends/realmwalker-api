# frozen_string_literal: true

class LeyLine < RealmLocation
  # enum status: { active: 1, expired: 0 }
  # store :properties, accessors: [ :level, :defeated_at, :defeated_by ], coder: JSON

  def name
    'Ley line'
  end

  def nearest_ley_line
    throw('Unable to determine competitive proximity for ley line') if coordinates.blank?

    point = "ST_GeographyFromText('POINT(#{coordinates.lon} #{coordinates.lat})')"
    distance_query = Arel.sql("ST_Distance(coordinates::geography, #{point})")

    ley_line = LeyLine.where.not(id: id)
                  .select("ley_lines.id, #{distance_query}")
                  .order(distance_query)
                  .limit(1)

    [ley_line, ley_line.pick(distance_query)] if ley_line.present?
  end
end
