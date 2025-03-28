# frozen_string_literal: true

require 'test_helper'

class PlayerActionHelperTest < ActiveSupport::TestCase
  setup do
    @user = generate_test_user
  end
  test 'should access universal actions' do
    available_actions_ids = PlayerActionHelper.for_player(@user).pluck(:id)
    assert_includes available_actions_ids, 'flee'
    assert_includes available_actions_ids, 'basic_attack'
  end
end
