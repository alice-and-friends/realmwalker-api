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
    add_dungeons(geolocation)
    add_shops(geolocation)
  end

  def self.add_dungeons(geolocation)
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

  def self.add_shops(geolocation)
    distance = 3_500 # There SHOULD be an armorer within x meters
    nearby_armorers_count = Npc.shopkeepers.where(shop_type: 'armorer').near(geolocation[:latitude], geolocation[:longitude], distance).count
    return if nearby_armorers_count.positive?

    transaction do
      # Check if there is an available location
      suitable_location = RealWorldLocation.available.for_shop.near(geolocation[:latitude], geolocation[:longitude], distance).first

      if suitable_location.nil?
        # If no suitable location found, adapt one
        suitable_location = RealWorldLocation.available.near(geolocation[:latitude], geolocation[:longitude], distance).first
        raise if suitable_location.nil?

        suitable_location.update(type: 'shop')
      end

      # Spawn the shop
      Npc.create(
        real_world_location_id: suitable_location.id,
        role: 'shopkeeper',
        shop_type: 'armorer',
        coordinates: suitable_location.coordinates,
        trade_offer_lists: [TradeOfferList.find_by(name: 'armorer')],
      )
    end
  end
end
