# frozen_string_literal: true

class Api::V1::DungeonsController < Api::V1::ApiController
  before_action :find_active_dungeon, only: %i[show analyze battle]

  def show
    render json: @dungeon
  end

  def analyze
    analysis = @dungeon.battle_prediction_for(@current_user)
    render json: analysis
  end

  def battle
    battle_report = @dungeon.battle_as(@current_user)
    render json: battle_report
  end

  private

  def find_active_dungeon
    dungeon_id = params[:action] == 'show' ? params[:id] : params[:dungeon_id]
    @dungeon = Dungeon.find(dungeon_id)
    if @dungeon.active? == false
      render json: {
        message: 'This dungeon is no longer active (defeated).',
        battlefield_id: Battlefield.find(@dungeon.id).pluck(:id)
      }, status: :see_other
    elsif @dungeon.expired?
      render json: {
        message: 'This dungeon is no longer active (expired).'
      }, status: :gone
    end
  end
end
