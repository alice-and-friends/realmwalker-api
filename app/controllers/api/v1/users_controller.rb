# frozen_string_literal: true

class Api::V1::UsersController < Api::V1::ApiController
  def me
    render json: @current_user
  end

  def update
    if @current_user.update(user_params)
      render json: @current_user
    else
      render json: @current_user.errors, status: :unprocessable_entity
    end
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

  def experience_table
    xp_table = []
    # Index 0 will correspond to level 1 and so forth
    100.times do |i|
      xp_table << User.total_xp_needed_for_level(i + 1)
    end

    render json: xp_table
  end

  private

  def user_params
    params.require(:user).permit(:name)
  end

  def preference_params
    params.require(:preferences).permit(:sound, :music, :developer, :item_frames, :dungeon_levels)
  end
end
