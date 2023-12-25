# frozen_string_literal: true

class CoordinatesValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    # Ensure that the value is a valid RGeo Point object
    return unless value.is_a?(RGeo::Geographic::SphericalPointImpl)

    # Get the latitude and longitude values from the Point object
    latitude = value.latitude
    longitude = value.longitude

    # Check if the latitude is exactly +90 or -90
    record.errors.add(attribute, 'cannot be +90 or -90') if attribute == :coordinates && [90.0, -90.0].include?(latitude)

    # Check if the longitude is exactly +180 or -180
    record.errors.add(attribute, 'cannot be +180 or -180') if attribute == :coordinates && [180.0, -180.0].include?(longitude)

    # Check if the latitude is within the valid range of -90 to +90 degrees
    record.errors.add(attribute, 'Latitude is out of range (-90 to +90 degrees)') unless (-90..90).cover?(latitude)

    # Check if the longitude is within the valid range of -180 to +180 degrees
    record.errors.add(attribute, 'Longitude is out of range (-180 to +180 degrees)') unless (-180..180).cover?(longitude)
  end
end
