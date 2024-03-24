# frozen_string_literal: true

require 'test_helper'

class LeyLineTest < ActiveSupport::TestCase
  test 'there are ley lines in the test database' do
    assert_operator LeyLine.count, :>, 0
  end
  test 'can capture ley line' do
    user = User.first
    ley_line = LeyLine.first
    ley_line.captured_by! user
    assert ley_line.captured?
    assert_includes ley_line.captured_by, user
    assert_operator ley_line.captured_at, :>, 5.seconds.ago
  end
end
