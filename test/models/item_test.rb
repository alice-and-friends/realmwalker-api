require "test_helper"

class ItemTest < ActiveSupport::TestCase
  test "There are items in the test database" do
    assert Item.count > 0
  end
end
