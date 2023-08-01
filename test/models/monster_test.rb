require "test_helper"

class MonsterTest < ActiveSupport::TestCase
  test "There are monsters in the test database" do
    assert Monster.count > 0
  end
end
