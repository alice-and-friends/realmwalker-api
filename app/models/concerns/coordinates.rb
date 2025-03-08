# frozen_string_literal: true

module Coordinates
  extend ActiveSupport::Concern
  class_methods do
    def point_factory
      RGeo::ActiveRecord::SpatialFactoryStore.instance.factory(geo_type: 'point')
    end
  end
  included do
    validates :coordinates, presence: true, coordinates: true # app/validators/coordinates_validator.rb

    scope :near, lambda { |latitude, longitude, distance|
      where("ST_DWithin(coordinates, 'POINT(#{longitude} #{latitude})', #{distance})")
    }

    scope :nearest, lambda { |latitude, longitude|
      select("#{table_name}.*, ST_Distance(coordinates, 'POINT(#{longitude} #{latitude})') AS distance")
        .order('distance ASC')
        .first
    }

    def self.night_time_zones
      time_zones = select(:timezone).pluck(:timezone).uniq.compact
      time_zones.filter_map do |tz|
        current_hour = Time.current.in_time_zone(tz).hour
        tz if current_hour.in? Event::NIGHT_TIME[:hours]
      end
    end

    def self.day_time_zones
      time_zones = select(:timezone).distinct.pluck(:timezone).compact
      time_zones.filter_map do |tz|
        current_hour = Time.current.in_time_zone(tz).hour
        tz unless current_hour.in? Event::NIGHT_TIME[:hours]
      end
    end

    # Method to return the current local time for the location
    # Since timezone is cached, the local time will not account for daylight savings.
    def approximate_local_time
      raise 'Timezone is blank' if timezone.blank?

      DateTimeHelper.time_in_zone timezone
    end

    def night_time?
      raise 'Timezone is blank' if timezone.blank?

      DateTimeHelper.night_time_in_zone? timezone
    end

    def day_time?
      !night_time?
    end

    # Destination can be either a Point or any class that implements the Coordinates module
    def distance(point)
      unless point.instance_of? RGeo::Geographic::SphericalPointImpl
        Rails.logger.error 'Unable to calculate distance between locations'
        return nil
      end
      coordinates.distance(point)
    end

    def debug
      [
        'Cmd + double click to open link from terminal:',
        "https://www.google.com/maps/place/#{coordinates.latitude},#{coordinates.longitude}",
        "https://www.openstreetmap.org/#{ext_id}",
      ]
    end
  end
end
