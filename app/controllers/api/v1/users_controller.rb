# frozen_string_literal: true

class Api::V1::UsersController < Api::V1::ApiController
  # before_action :set_api_v1_user, only: [:show, :update, :destroy]

  def me
    render json: @current_user, status: :ok
  end

  def update_preference
    # Convert parameters to a hash and merge with existing preferences to retain other preferences
    updated_preferences = @current_user.preferences.merge(preference_params.to_h)

    if @current_user.update(preferences: updated_preferences)
      render json: @current_user.preferences, status: :ok
    else
      render json: @current_user.errors, status: :unprocessable_entity
    end
  end

  private

  # # Only allow a trusted parameter "white list" through.
  def preference_params
    params.require(:preferences).permit(:developer, :item_frames)
  end
end
