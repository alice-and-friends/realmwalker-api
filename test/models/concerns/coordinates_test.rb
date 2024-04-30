# frozen_string_literal: true

require 'test_helper'

class CoordinatesTest < ActiveSupport::TestCase
  test 'calculate distance between points' do
    test_user_location = generate_test_user_location
    nearby_location = generate_nearby_location
    far_away_location = generate_far_away_location

    assert test_user_location.distance(nearby_location).positive?
    assert_operator test_user_location.distance(nearby_location), :<, 1_000
    assert_operator test_user_location.distance(far_away_location), :>, 1_000
  end
  test 'calculate distance to realm location' do
    test_user_location = generate_test_user_location
    some_npc = Npc.last

    assert test_user_location.distance(some_npc.coordinates).positive?
  end
end
