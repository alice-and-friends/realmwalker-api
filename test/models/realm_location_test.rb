require 'test_helper'

class RealmLocationTest < ActiveSupport::TestCase
  test 'gets list of currently active real world locations' do
    # Check that we get a list
    list = RealWorldLocation.ids_currently_in_use
    assert_operator list.length, :>, 1

    # Find a location from the list
    location_id = list.first
    a_current_location = (
      Dungeon.where(real_world_location_id: location_id) +
      Battlefield.where(real_world_location_id: location_id) +
      Npc.where(real_world_location_id: location_id)
    ).first
    assert_not_nil a_current_location

    # Destroy the location and check if it disappears from the list
    a_current_location.destroy!
    new_list = RealWorldLocation.ids_currently_in_use
    assert_not_includes new_list, location_id
  end
end
