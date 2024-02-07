# frozen_string_literal: true

class Api::V1::RealmLocationsController < Api::V1::ApiController
  def index
    # Activate the area around the player (spawn monsters and such)
    ActivePlayerArea.activate(@current_user_geolocation)

    # Get common locations (visible to all players)
    @locations = RealmLocation.where.not(type: 'Npc').player_vision_radius(@current_user_geolocation) +
                 Npc.player_vision_radius(@current_user_geolocation).with_spook_status

    # Get personal locations (visible to this player)
    @locations << @current_user.base if @current_user.base.present?

    render json: @locations, each_serializer: RealmLocationSerializer
  end
end
