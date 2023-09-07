class Api::V1::RealmLocationsController < Api::V1::ApiController
  def index
    @locations = Dungeon.player_vision_radius(@current_user_geolocation).active +
                 Battlefield.player_vision_radius(@current_user_geolocation).active +
                 Npc.player_vision_radius(@current_user_geolocation)
    render json: @locations, each_serializer: RealmLocationSerializer
  end
end
