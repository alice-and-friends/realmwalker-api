require "test_helper"

class NpcTest < ActiveSupport::TestCase
  test "There are npcs in the test database" do
    assert Npc.count > 0
  end
end
