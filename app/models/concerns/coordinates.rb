# frozen_string_literal: true

module Coordinates
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
      select("#{table_name}.*, ST_Distance(coordinates, 'POINT(#{longitude} #{latitude})') AS distance")
        .order('distance ASC')
        .first
    }

    def timezone
      return self[:timezone] unless self[:timezone].nil?

      begin
        timezone = Timezone.lookup(self.latitude, self.longitude)
        update(timezone: timezone.name) # Update the record with the fetched timezone
        self[:timezone] # Return the newly set timezone
      rescue StandardError => e
        Rails.logger.error "Failed to fetch timezone for #{self.class.name} #{id}: #{e.message}"
        nil # Gracefully handle errors by returning nil
      end
    end

    # Method to return the current local time for the location
    # Since timezone is cached, the local time will not account for daylight savings.
    def approximate_local_time
      raise 'Timezone is blank' if timezone.blank?

      begin
        # Use ActiveSupport's in_time_zone method to convert Time.current to the location's timezone
        Time.current.in_time_zone(timezone)
      rescue StandardError => e
        Rails.logger.error "Failed to calculate local time for #{self.class.name} #{id}: #{e.message}"
        raise "Failed to calculate local time for #{self.class.name} #{id}: #{e.message}"
      end
    end

    def night?
      raise 'Local time not available' unless approximate_local_time&.hour

      night_hours = (21..23).to_a + (0..7).to_a
      current_hour = approximate_local_time.hour
      night_hours.include?(current_hour)
    rescue StandardError => e
      Rails.logger.error "Failed to determine if it's night for #{self.class.name} #{id}: #{e.message}"
      raise "Failed to determine if it's night for #{self.class.name} #{id}: #{e.message}"
    end

    def day?
      !night?
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
