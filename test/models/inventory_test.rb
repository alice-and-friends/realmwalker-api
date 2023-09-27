# frozen_string_literal: true

require 'test_helper'

class InventoryTest < ActiveSupport::TestCase
  test 'can have zero gold but not negative' do
    user = generate_test_user
    assert_nothing_raised do
      user.inventory.update!(gold: 1)
      user.inventory.update!(gold: 0)
    end
    assert_raise(Exception) do
      user.inventory.update!(gold: -1)
    end
  end
end
