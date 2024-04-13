# frozen_string_literal: true

class Api::V1::UsersController < Api::V1::ApiController
  def me
    render json: @current_user
  end

  def update_preference
    # Convert parameters to a hash and merge with existing preferences to retain other preferences
    updated_preferences = @current_user.preferences.merge(preference_params.to_h)

    if @current_user.update(preferences: updated_preferences)
      render json: @current_user.preferences
    else
      render json: @current_user.errors, status: :unprocessable_entity
    end
  end

  private

  # Only allow trusted parameters through.
  def preference_params
    params.require(:preferences).permit(:developer, :item_frames)
  end
end
