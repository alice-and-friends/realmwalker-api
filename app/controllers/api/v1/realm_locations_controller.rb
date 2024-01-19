# frozen_string_literal: true

class Api::V1::RealmLocationsController < Api::V1::ApiController
  def index

    # Common locations
    @locations = Dungeon.player_vision_radius(@current_user_geolocation).active.includes(:monster) +
                 Battlefield.player_vision_radius(@current_user_geolocation).active +
                 Npc.with_spook_status.player_vision_radius(@current_user_geolocation)

    # Personal locations
    @locations << @current_user.base if @current_user.base.present?

    render json: @locations, each_serializer: RealmLocationSerializer
  end
end
