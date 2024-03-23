# frozen_string_literal: true

require 'test_helper'

class RealWorldTest < ActiveSupport::TestCase
  test 'there are real world locations in the test database' do
    assert_operator RealWorldLocation.count, :>, 0
  end
end
