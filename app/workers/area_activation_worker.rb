# frozen_string_literal: true

class AreaActivationWorker
  include Sidekiq::Job
  sidekiq_options queue: 'environment-normal'

  def perform(latitude, longitude)
    geolocation = RealWorldLocation.point_factory.point(longitude, latitude)

    # Ensure that there is an armorer near the coordinates
    add_npc(geolocation, shop_type: 'armorer', npc_role: 'shopkeeper', distance: 3_500, trade_offer_list_name: 'armorer')

    # Ensure that there is a castle near the coordinates
    add_npc(geolocation, shop_type: 'castle', npc_role: 'castle', distance: 7_000, trade_offer_list_name: 'castle')
  end

  def add_npc(geolocation, shop_type:, npc_role:, distance:, trade_offer_list_name:)
    nearby_npcs_count = Npc.where(shop_type: shop_type).near(geolocation.latitude, geolocation.longitude, distance).count
    return if nearby_npcs_count.positive?

    Npc.transaction do
      # Check if there is an available location
      scope_method = npc_role == 'castle' ? :for_castle : :for_shop
      suitable_location = RealWorldLocation.available.send(scope_method).near(geolocation.latitude, geolocation.longitude, distance).first

      if suitable_location.nil?
        # If no suitable location found, adapt one
        suitable_location = RealWorldLocation.available.near(geolocation.latitude, geolocation.longitude, distance).first
        raise 'Could not find any location' if suitable_location.nil?

        suitable_location.update(type: RealWorldLocation.types[shop_type.to_sym])
      end

      # Spawn the NPC
      Npc.create(
        real_world_location_id: suitable_location.id,
        role: npc_role,
        shop_type: shop_type,
        coordinates: suitable_location.coordinates,
        trade_offer_lists: [TradeOfferList.find_by(name: trade_offer_list_name)],
      )
    end
  end
end
