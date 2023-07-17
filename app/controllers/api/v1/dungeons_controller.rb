class Api::V1::DungeonsController < Api::V1::ApiController
  before_action :authorize
  before_action :find_dungeon, only: [:show, :battle]

  def show
    render json: @dungeon
  end

  def battle
    puts "⚔️ #{@current_user.given_name} started battle against #{@dungeon}"
    defeated = @dungeon.battle
    render json: {defeated: defeated}
  end

  private
  def find_dungeon
    @dungeon = Dungeon.find(params[:id])
    puts @dungeon.inspect
  end
end
