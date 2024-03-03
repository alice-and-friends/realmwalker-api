# frozen_string_literal: true

class Api::V1::RealmLocationsController < Api::V1::ApiController
  def index
    # Activate the area around the player (spawn monsters and such)
    ActivePlayerArea.activate(@current_user_geolocation)

    # Get common locations (visible to all players)
    @locations = Npc.player_vision_radius(@current_user_geolocation).with_spook_status +
                 RealmLocation.where.not(type: 'Npc').where.not(status: Dungeon.statuses[:expired]).player_vision_radius(@current_user_geolocation)

    # Get personal locations (visible to this player)
    @locations << @current_user.base if @current_user.base.present?

    # Mark locations as seen
    LocationRelevanceWorker.perform_async(
      @locations.pluck(:real_world_location_id),
      RealWorldLocation.relevance_grades[:seen],
    )

    render json: @locations, each_serializer: RealmLocationSerializer
  end
end
