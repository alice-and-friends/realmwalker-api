class Api::V1::DungeonsController < ApplicationController
  include Secured
  before_action :find_dungeon, only: [:show, :battle]

  def show
    render json: @dungeon
  end

  def battle
    puts 'battle called'
    defeated = @dungeon.battle
    render json: {defeated: defeated}
  end

  private
  def find_dungeon
    puts 'find_dungeon called'
    @dungeon = Dungeon.find(params[:id])
    puts @dungeon.inspect
  end
end
