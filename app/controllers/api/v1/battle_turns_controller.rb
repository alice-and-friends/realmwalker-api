# frozen_string_literal: true

class Api::V1::BattleTurnsController < Api::V1::ApiController
  before_action :find_battle
  before_action :find_turn
  before_action :authorize_actor, only: [:update]

  def update
    # TODO: Do stuff to @turn and @battle
  end

  private

  def find_battle
    @battle = Battle.find(params[:battle_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Battle not found' }, status: :not_found
  end

  def find_turn
    @turn = @battle.turns.find(params[:battle_turn_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Battle turn not found' }, status: :not_found
  end

  def authorize_actor
    render json: { error: 'Not your turn' }, status: :forbidden unless @turn.actor == @current_user
  end

  # def find_opponent(id, type)
  #   type.constantize.find(id) # Converts "User" or "Dungeon" into a class
  # end
end
