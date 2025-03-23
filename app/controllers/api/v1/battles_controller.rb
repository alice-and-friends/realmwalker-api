# frozen_string_literal: true

class Api::V1::BattlesController < Api::V1::ApiController
  before_action :find_opponent, only: [:create]
  before_action :find_battle, only: [:show]

  def show
    render json: @battle, serializer: BattleSerializer, user: @current_user
  end

  def create
    @battle = nil # Declare outside to retain scope
    http_status = :ok

    Battle.transaction do
      @current_user&.abandon_stale_battles!

      # Find the requested battle or create it
      @battle = Battle
                .ongoing
                .select(:id, :status)
                .find_or_initialize_by(player: @current_user, opponent: @opponent)

      if @battle&.new_record?
        @current_user&.abandon_ongoing_battles!
        @battle.save!
        http_status = :created
      end
    end

    # Render response after the transaction commits
    render json: { battle_id: @battle&.id }, status: http_status
  end

  private

  def battle_params
    params.require(:battle).permit(:opponent_id, :opponent_type)
  end

  def find_battle
    id = params[:id]
    @battle = Battle.find(id)
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Battle##{id} not found" }, status: :not_found
  end

  def find_opponent
    valid_types = %w[User Dungeon]
    type, id = battle_params.values_at(:opponent_type, :opponent_id)
    if type.in? valid_types
      @opponent = type.constantize.find(id)
    else
      render json: { error: "Invalid opponent type, use one of #{valid_types.join(', ')}" }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Opponent not found' }, status: :not_found
  end
end
