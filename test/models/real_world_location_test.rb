require "test_helper"

class RealWorldTest < ActiveSupport::TestCase
  test "There are real world locations in the test database" do
    assert RealWorldLocation.count > 0
  end
end
