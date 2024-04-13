# frozen_string_literal: true

class Api::V1::DailyRewardsController < Api::V1::ApiController
  before_action :set_reward_service

  # GET /api/v1/daily_rewards
  def show
    render json: @reward_service.json
  end

  # POST /api/v1/daily_rewards/claim
  def claim
    @reward_service.claim!
    render json: @reward_service.json
  rescue RuntimeError => e
    Rails.logger.error(e)
    render json: @reward_service.json, status: :unprocessable_entity
  end

  private

  def set_reward_service
    @reward_service = DailyReward.new(@current_user)
  end
end

