# frozen_string_literal: true

class Api::V1::DungeonsController < Api::V1::ApiController
  before_action :find_dungeon
  before_action :location_inspected, only: %i[show]
  before_action :must_not_be_expired
  before_action :location_interacted, only: %i[analyze battle]
  before_action :must_not_be_defeated, only: %i[analyze battle]

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

  def find_dungeon
    dungeon_id = params[:action] == 'show' ? params[:id] : params[:dungeon_id]
    @dungeon = Dungeon.find(dungeon_id)
    render status: :not_found if @dungeon.nil?
  end

  def location_inspected
    @dungeon.real_world_location.inspected!
  end

  def location_interacted
    @dungeon.real_world_location.interacted!
  end

  def must_not_be_expired
    return unless @dungeon.expired?

    render json: {
      message: 'This dungeon is no longer active (expired).',
    }, status: :gone
  end

  def must_not_be_defeated
    return unless @dungeon.defeated?

    render json: {
      message: 'This dungeon is no longer active (defeated).',
    }, status: :method_not_allowed
  end
end
