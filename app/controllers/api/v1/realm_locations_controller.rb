class Api::V1::RealmLocationsController < ApplicationController
  include Secured
  def index
    @locations = Dungeon.active + Battlefield.active + Npc.all
    render json: @locations
  end
end
