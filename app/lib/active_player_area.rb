# frozen_string_literal: true

class ActivePlayerArea
  DESIRED_DUNGEONS = [

    # There SHOULD be a level 1 monster in my immediate area
    {
      target: 1,
      level: 1,
      distance: 180,
    },

    # There SHOULD be at least 6 monsters in my city district
    {
      target: 6,
      distance: 720,
    },

    # There SHOULD be at least 1 monsters per 555 meters of vision radius (e.g. 18 monsters if radius is 10,000 meters)
    {
      target: (RealmLocation::PLAYER_VISION_RADIUS / 555).round,
      distance: RealmLocation::PLAYER_VISION_RADIUS,
    },
  ].freeze

  # TODO: Maybe some of this should be delegated to a worker, so that it doesn't slow down requests?
  def self.activate(geolocation)
    new_dungeons = 0
    max_new_dungeons_per_activation = 9 # The highest number of dungeons that can be spawned by a single call to this function

    DESIRED_DUNGEONS.each do |layer|
      # Potential TODO: Should we only count active dungeons here?
      dungeons_in_range = Dungeon.near(geolocation[:latitude], geolocation[:longitude], layer[:distance]).count
      missing = layer[:target] - dungeons_in_range
      next if missing <= 0

      potential_locations = RealWorldLocation.available.near(geolocation[:latitude], geolocation[:longitude], layer[:distance]).pluck(:id)
      next if potential_locations.empty?

      missing.times do
        # Create a new dungeon
        Dungeon.create(
          real_world_location_id: potential_locations.pop,
          level: layer[:level],
        )
        new_dungeons += 1
        break if potential_locations.empty?
        break if new_dungeons >= max_new_dungeons_per_activation
      end
      break if new_dungeons >= max_new_dungeons_per_activation
    end
  end
end
