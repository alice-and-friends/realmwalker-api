# frozen_string_literal: true

module ComfyCoordinates
  extend ActiveSupport::Concern
  class_methods do
    def point_factory
      RGeo::ActiveRecord::SpatialFactoryStore.instance.factory(geo_type: 'point')
    end

    def debug
      "https://www.google.com/maps/place/#{coordinates.lat},#{coordinates.lon} (cmd + double click)"
    end
  end
  included do
    validates :coordinates, presence: true, coordinates: true

    scope :near, lambda { |latitude, longitude, distance|
      where("ST_DWithin(coordinates, 'POINT(#{longitude} #{latitude})', #{distance})")
    }

    scope :nearest, lambda { |latitude, longitude|
      order(Arel.sql(
        "ST_Distance(coordinates, ST_GeographyFromText('POINT(#{longitude.to_s} #{latitude.to_s})'))"
      )).first
    }
  end
end
