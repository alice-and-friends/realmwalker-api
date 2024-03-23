# frozen_string_literal: true

require 'test_helper'

class MonsterTest < ActiveSupport::TestCase
  test 'there are monsters in the test database' do
    assert_operator Monster.count, :>, 0
  end
end
