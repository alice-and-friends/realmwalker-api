# frozen_string_literal: true

require 'test_helper'

class RenewableTest < ActiveSupport::TestCase
  test 'there are renewables in the test database' do
    assert_operator Renewable.count, :>, 0
  end
  test 'renewable has inventory' do
    renewable = Renewable.create!(real_world_location: RealWorldLocation.available.sample)
    assert_not_nil renewable.inventory
  end
  test 'renewable grows' do
    renewable = Renewable.create!(real_world_location: RealWorldLocation.available.sample)
    assert_equal 0, renewable.inventory.inventory_items.count
    2.times { renewable.grow! }
    assert_equal 2, renewable.inventory.inventory_items.count
  end
end
