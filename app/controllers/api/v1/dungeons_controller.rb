class Api::V1::DungeonsController < Api::V1::ApiController
  before_action :authorize
  before_action :find_active_dungeon, only: [:show, :battle]

  def show
    render json: @dungeon
  end

  def battle
    puts "⚔️ #{@current_user.name} started battle against #{@dungeon}"
    battle_report = @dungeon.battle_as(@current_user)
    render json: battle_report
  end

  private
  def find_active_dungeon
    @dungeon = Dungeon.find(params[:id])
    if @dungeon.active? == false
      render json: {
        message: 'This dungeon is no longer active.',
        battlefield_id: Battlefield.find_by_dungeon_id(@dungeon.id).id
      }, :status => :see_other
    elsif @dungeon.expired?
      render json: {
        message: 'This dungeon is no longer active.'
      }, :status => :gone
    end
  end
end
