# frozen_string_literal: true

require 'test_helper'

class DateTimeHelperTest < ActiveSupport::TestCase
  setup do
    # Define a stub for Timezone.lookup to return a mock object with a name method
    Timezone.define_singleton_method(:lookup) do |lat, lon|
      OpenStruct.new(name: 'Europe/Oslo')
    end
  end
  teardown do
    # Restore the original Timezone.lookup method after each test
    Timezone.singleton_class.remove_method(:lookup)
  end
  test 'returns correct timezone' do
    oslo_latitude = 59.907887
    oslo_longitude = 10.751164
    timezone = DateTimeHelper.timezone_at_coordinates(oslo_latitude, oslo_longitude)
    assert_equal 'Europe/Oslo', timezone
  end
end
