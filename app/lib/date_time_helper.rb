# frozen_string_literal: true

class DateTimeHelper
  def self.timezone_at_coordinates(*coordinates)
    Timezone.lookup(*coordinates).name
  rescue StandardError => e
    raise "Failed to fetch timezone: #{e.message}"
  end

  def self.time_in_zone(timezone)
    Time.current.in_time_zone(timezone)
  rescue StandardError => e
    raise "Failed to calculate local time: #{e.message}"
  end

  def self.time_at_coordinates(*coordinates)
    tz = timezone_at_coordinates(*coordinates)
    return nil if tz.blank? # Gracefully handle error

    time_in_zone(tz)
  end

  def self.night_time_at_coordinates?(*coordinates)
    tz = timezone_at_coordinates(*coordinates)
    return false if tz.blank? # Gracefully handle error

    night_time_in_zone?(tz)
  end

  def self.night_time_in_zone?(timezone)
    return false if timezone.blank? # Gracefully handle error

    current_hour = time_in_zone(timezone)&.hour
    night_hours = Event::NIGHT_TIME[:hours]
    night_hours.include?(current_hour)
  rescue StandardError => e
    raise "Failed to determine if it's night: #{e.message}"
  end

  def self.day_time_at_coordinates?(*args)
    !night_time_at_coordinates?(*args)
  end

  def self.day_time_in_zone?(*args)
    !night_time_in_zone?(*args)
  end
end
