# frozen_string_literal: true

require 'test_helper'

class DailyRewardTest < ActiveSupport::TestCase
  setup do

  end
  teardown do
    Timecop.return
  end

  test 'should claim reward successfully' do
    user = users(:jane_doe)
    reward = DailyReward.new(user)

    reward_time = Time.zone.now
    Timecop.freeze(reward_time) do
      reward.claim!
      assert_equal 1, user.reward_streak
      assert_equal Time.zone.now, user.reward_claimed_at
    end

    # Claim again the next day
    reward_time += 1.day
    Timecop.freeze(reward_time) do
      reward.claim!
      assert_equal 2, user.reward_streak
      assert_equal Time.zone.now, user.reward_claimed_at
    end
  end

  test 'cannot claim reward twice in the same period' do
    user = users(:jane_doe)
    reward = DailyReward.new(user)
    reward_time = Time.zone.now

    # First claim at the exact time reward becomes available
    Timecop.freeze(reward_time) do
      reward.claim!
    end

    # Attempt second claim just minutes after the first claim
    Timecop.freeze(reward_time + 10.minutes) do
      assert reward.already_claimed?
      assert_raises(RuntimeError) { reward.claim! }
    end
  end

  test 'should reset reward streak' do
    user = users(:jane_doe)
    reward = DailyReward.new(user)

    reward_time = Time.zone.now
    Timecop.freeze(reward_time) do
      reward.claim!
      assert_equal 1, user.reward_streak
    end

    # Claim again two days later, streak is expected to reset
    reward_time += 2.days + 1.second
    Timecop.freeze(reward_time) do
      reward.claim!
      assert_equal 1, user.reward_streak
    end
  end
end
