class Api::V1::DungeonsController < Api::V1::ApiController
  before_action :authorize
  before_action :find_dungeon, only: [:show, :battle]

  def show
    if @dungeon.active?
      render json: @dungeon
    else
      render :status => 404
    end
  end

  def battle
    puts "⚔️ #{@current_user.given_name} started battle against #{@dungeon}"
    defeated = @dungeon.battle_as(@current_user)
    render json: {success: defeated}
  end

  private
  def find_dungeon
    @dungeon = Dungeon.active.find(params[:id])
  end
end
