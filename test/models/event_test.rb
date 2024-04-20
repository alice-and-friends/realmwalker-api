# frozen_string_literal: true

require 'test_helper'

class EventTest < ActiveSupport::TestCase
  test 'active scope includes night time event' do
    # Freeze time at 01:00 UTC
    Timecop.freeze(Time.utc(2024, 1, 1, 1, 0, 0)) do
      assert_includes Event.active('UTC'), Event.night_time
    end
  end
  test 'active scope excludes night time event' do
    # Freeze time at 18:00 UTC
    Timecop.freeze(Time.utc(2024, 1, 1, 18, 0, 0)) do
      assert_not_includes Event.active('UTC'), Event.night_time
    end
  end
end
