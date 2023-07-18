class Api::V1::RealmLocationsController < Api::V1::ApiController
  before_action :authorize
  def index
    @locations = Dungeon.active + Battlefield.active + Npc.all
    render json: @locations, each_serializer: RealmLocationSerializer
  end
end
