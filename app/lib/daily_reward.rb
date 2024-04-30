# frozen_string_literal: true

class DailyReward
  require 'date'
  require 'time'

  # Time when the reward becomes available each day
  REWARD_AVAILABLE_HOUR = 20 # 20:00 UTC

  def initialize(user)
    @user = user
  end

  def claim!
    # Check if the user is eligible to claim the reward
    raise 'You have already claimed your daily reward.' if already_claimed?

    # Update the user's streak
    if can_maintain_streak?
      @user.reward_streak += 1
    else
      @user.reward_streak = 1
    end

    # Set reward_claimed_at to the current time
    @user.reward_claimed_at = Time.zone.now

    # Dispense the reward
    dispense

    @user.save
  end

  def claimable?
    !already_claimed?
  end

  def already_claimed?
    return false unless @user.reward_claimed_at

    @user.reward_claimed_at > next_reward_reset_time - 1.day
  end

  def can_maintain_streak?
    return false unless @user.reward_claimed_at

    @user.reward_claimed_at > next_reward_reset_time - 2.days
  end

  def json
    {
      claimable: claimable?,
      next_reward_at: next_reward_reset_time,
      streak: @user.reward_streak,
    }
  end

  private

  def dispense
    # TODO: Give stuff to user
  end

  def next_reward_reset_time
    now = Time.zone.now
    today_reward_time = Time.new(now.year, now.month, now.day, REWARD_AVAILABLE_HOUR, 0, 0, '+00:00')

    if now.hour < REWARD_AVAILABLE_HOUR
      today_reward_time
    else
      today_reward_time + 1.day
    end
  end
end

