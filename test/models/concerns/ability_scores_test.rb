# frozen_string_literal: true

require 'test_helper'

class AbilityScoresTest < ActiveSupport::TestCase
  test 'ability score improvement allotment' do
    # Should have 0 allotments at level 4
    test_user = generate_test_user(4)
    assert_equal 0, test_user.asi_allotment

    # Should have 1 allotments at level 5
    test_user = generate_test_user(5)
    assert_equal 1, test_user.asi_allotment

    # Should have 20 allotments at level 100
    test_user = generate_test_user(100)
    assert_equal 20, test_user.asi_allotment
  end
  test 'fail validation if ability score improvement exceeding allotment' do
    test_user = generate_test_user
    test_user.ability_score_improvements << User.abilities[:dexterity]
    assert_not test_user.valid?
  end
  test 'reject invalid ability score improvement' do
    test_user = generate_test_user
    test_user.ability_score_improvements << 'XYZ'
    assert_not test_user.valid?
  end
  test 'ability score calculations' do
    # Base
    test_user = generate_test_user
    assert_equal AbilityScores::ABILITY_SCORE_BASE, test_user.ability_score(User.abilities[:dexterity])

    # With improvements
    improvements = 2
    test_user = generate_test_user(improvements * 5)
    improvements.times do
      test_user.improve_ability!(User.abilities[:dexterity])
    end
    assert_equal (AbilityScores::ABILITY_SCORE_BASE + improvements), test_user.ability_score(User.abilities[:dexterity])
  end
  test 'should lose ability score improvement on death' do
    test_user = generate_test_user(5)
    test_user.improve_ability!(User.abilities[:dexterity])
    test_user.handle_death
    assert_empty test_user.reload.ability_score_improvements
  end
end
