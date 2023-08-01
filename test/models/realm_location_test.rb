require "test_helper"

class RealmLocationTest < ActiveSupport::TestCase
  test "gets list of currently active real world locations" do
    # Check that we get a list
    list = RealmLocation::real_world_location_ids_currently_in_use
    assert list.length > 1

    # Find a location from the list
    location_id = list.first
    a_current_location = (
      Dungeon.where(real_world_location_id: location_id) +
      Battlefield.where(real_world_location_id: location_id) +
      Npc.where(real_world_location_id: location_id)
    ).first
    assert a_current_location.present?

    # Destroy the location and check if it disappears from the list
    a_current_location.destroy!
    new_list = RealmLocation::real_world_location_ids_currently_in_use
    assert_not location_id.in? new_list
  end
end
