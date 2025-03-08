# frozen_string_literal: true

class ActivePlayerArea
  DESIRED_DUNGEONS = [
    # There SHOULD be at least 2 low level monsters in my immediate area
    {
      target: 1,
      level_range: 1..5,
      distance: 250,
    },
    {
      target: 2,
      level_range: 1..10,
      distance: 500,
    },
    # There SHOULD be at least 6 monsters in my city district
    {
      target: 6,
      level_range: 1..50,
      distance: 720,
    },
    # There SHOULD be at least 1 monsters per 555 meters of vision radius (e.g. 18 monsters if radius is 10,000 meters)
    {
      target: (RealmLocation::PLAYER_VISION_RADIUS / 555).round,
      level_range: 1..100,
      distance: RealmLocation::PLAYER_VISION_RADIUS,
      stop_after: 1,
    },
  ].freeze

  def self.activate(geolocation)
    add_dungeons(geolocation)
    AreaActivationWorker.perform_async(geolocation.latitude, geolocation.longitude)
  end

  def self.add_dungeons(geolocation)
    new_dungeons = []
    max_new_dungeons_per_activation = 6 # The highest number of dungeons that can be spawned by a single call to this function

    DESIRED_DUNGEONS.each do |layer|
      dungeons_in_range = Dungeon.visible.where(level: layer[:level_range]).near(geolocation.latitude, geolocation.longitude, layer[:distance]).count
      missing = layer[:target] - dungeons_in_range
      next if missing <= 0

      @monster_pool ||= Monster.weighted_pool_for_timezone DateTimeHelper.timezone_at_coordinates(geolocation.latitude, geolocation.longitude)
      @level_appropriate_pool = nil

      potential_locations_ids = RealWorldLocation.available
                                                 .near(geolocation.latitude, geolocation.longitude, layer[:distance])
                                                 .order('RANDOM()')
                                                 .limit(max_new_dungeons_per_activation)
                                                 .pluck(:id)

      planned_attempts = [missing, potential_locations_ids.size].min
      planned_attempts.times do |layer_attempt_nr|
        # Create a new dungeon
        location = RealWorldLocation.find(potential_locations_ids.pop)
        dungeon = Dungeon.new(
          real_world_location: location,
          timezone: location.timezone,
        )
        if layer[:level_range].present?
          @level_appropriate_pool ||= @monster_pool.select { |o| o[:level].in? layer[:level_range] }
          dungeon.monster = Monster.find(@level_appropriate_pool.sample[:id])
        end
        dungeon.save!
        new_dungeons << dungeon

        return new_dungeons if new_dungeons.size >= max_new_dungeons_per_activation
        break if (layer_attempt_nr + 1) == layer[:stop_after]
      end
    end
    new_dungeons
  end
end
