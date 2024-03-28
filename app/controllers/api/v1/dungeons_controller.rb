# frozen_string_literal: true

class Api::V1::DungeonsController < Api::V1::ApiController
  before_action :find_dungeon
  before_action :location_inspected, only: %i[show]
  before_action :must_not_be_expired
  before_action :location_interacted, only: %i[analyze battle]
  before_action :must_not_be_defeated, only: %i[analyze battle]

  def show
    render json: @ley_line, serializer: DungeonSerializer
  end

  def analyze
    analysis = @ley_line.battle_prediction_for(@current_user)
    render json: analysis
  end

  def battle
    battle_report = @ley_line.battle_as(@current_user)
    render json: battle_report
  end

  private

  def find_dungeon
    dungeon_id = params[:action] == 'show' ? params[:id] : params[:dungeon_id]
    @ley_line = Dungeon.find_by(id: dungeon_id)
    render status: :not_found unless @ley_line
  end

  def location_inspected
    @ley_line.real_world_location.inspected!
  end

  def location_interacted
    @ley_line.real_world_location.interacted!
  end

  def must_not_be_expired
    return unless @ley_line.expired?

    render json: {
      message: 'This dungeon is no longer active (expired).',
    }, status: :gone
  end

  def must_not_be_defeated
    return unless @ley_line.defeated?

    render json: {
      message: 'This dungeon is no longer active (defeated).',
    }, status: :method_not_allowed
  end
end
