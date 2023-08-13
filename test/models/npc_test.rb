require 'test_helper'

class NpcTest < ActiveSupport::TestCase
  test 'there are npcs in the test database' do
    assert_operator Npc.count, :>, 0
  end
end
