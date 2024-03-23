# frozen_string_literal: true

require 'test_helper'

class ItemTest < ActiveSupport::TestCase
  test 'there are items in the test database' do
    assert_operator Item.count, :>, 0
  end
end
