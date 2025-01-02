# frozen_string_literal: true

class Api::V1::DungeonsController < Api::V1::ApiController
  before_action :find_dungeon
  before_action :location_inspected, only: %i[show]
  before_action :must_not_be_expired
  before_action :location_interacted, only: %i[analyze battle]
  before_action :must_not_be_defeated, only: %i[analyze battle]

  def show
    render json: @dungeon, serializer: DungeonSerializer, seen_from: @current_user_geolocation
  end

  def analyze
    analysis = @dungeon.battle_prediction_for(@current_user)
    render json: analysis
  end

  def battle
    battle_report = @dungeon.battle_as(@current_user)
    render json: battle_report
  end

  def search
    if @dungeon.active?
      render json: ErrorResponse.new(
        message: 'Not possible on active dungeon, try defeating any monster(s) first.',
      ), status: :method_not_allowed and return
    end

    loot_container = @dungeon.search_defeated_dungeon(@current_user)
    @current_user.gains_loot(loot_container)
    render json: {
      dungeon: ActiveModelSerializers::SerializableResource.new(@dungeon, serializer: DungeonSerializer),
      loot: loot_container,
    }
  end

  private

  def find_dungeon
    dungeon_id = params[:action] == 'show' ? params[:id] : params[:dungeon_id]
    @dungeon = Dungeon.find_by(id: dungeon_id)
    render status: :not_found unless @dungeon
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
