# frozen_string_literal: true

require 'test_helper'

class DateTimeHelperTest < ActiveSupport::TestCase
  test 'returns correct timezone' do
    oslo_latitude = 59.907887
    oslo_longitude = 10.751164
    timezone = DateTimeHelper.timezone_at_coordinates(oslo_latitude, oslo_longitude)
    assert_equal 'Europe/Oslo', timezone
  end
end
