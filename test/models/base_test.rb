# frozen_string_literal: true

require 'test_helper'

class BaseTest < ActiveSupport::TestCase
  test 'user can construct a base' do
    user = generate_test_user
    base = user.construct_base_at(generate_test_user_location)
    assert_not_nil base.created_at
  end
  test 'exception raised when trying to build additional base' do
    user = generate_test_user
    user.construct_base_at(generate_test_user_location)
    assert_raise(Exception) { user.construct_base_at(generate_test_user_location) }
  end
  test 'WHEN deleting user, SHOULD also delete their structures and their inventories' do
    user = generate_test_user
    user.construct_base_at(generate_test_user_location)

    user_count = User.count
    structure_count = Base.count
    inventory_count = Inventory.count

    user.destroy!
    assert_equal user_count - 1, User.count
    assert_equal structure_count - 1, Base.count
    assert_equal inventory_count - 2, Inventory.count
  end
end
