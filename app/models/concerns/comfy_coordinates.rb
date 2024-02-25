# frozen_string_literal: true

module ComfyCoordinates
  extend ActiveSupport::Concern
  class_methods do
    def point_factory
      RGeo::ActiveRecord::SpatialFactoryStore.instance.factory(geo_type: 'point')
    end
  end
  included do
    validates :coordinates, presence: true, coordinates: true

    scope :near, lambda { |latitude, longitude, distance|
      where("ST_DWithin(coordinates, 'POINT(#{longitude} #{latitude})', #{distance})")
    }

    scope :nearest, lambda { |latitude, longitude|
      select("#{table_name}.*, ST_Distance(coordinates, ST_GeographyFromText('POINT(#{longitude} #{latitude})')) AS distance")
        .order('distance ASC')
        .first
    }

    def debug
      [
        'Cmd + double click to open link from terminal:',
        "https://www.google.com/maps/place/#{coordinates.latitude},#{coordinates.longitude}",
        "https://www.openstreetmap.org/#{ext_id}",
      ]
    end
  end
end
