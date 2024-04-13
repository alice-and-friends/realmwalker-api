# frozen_string_literal: true

require 'test_helper'

class Api::V1::UsersControllerTest < ActionDispatch::IntegrationTest
  test 'should get my user' do
    api_user = users(:jane_doe)
    get '/api/v1/users/me', headers: generate_headers
    assert_response :ok
    assert_equal api_user.id, response.parsed_body['id']
    assert_equal api_user.name, response.parsed_body['name']

    # Daily Reward
    assert_not_nil response.parsed_body['dailyReward']
    assert response.parsed_body['dailyReward']['claimable']
    assert_instance_of Integer, response.parsed_body['dailyReward']['streak']
    assert response.parsed_body['dailyReward']['nextRewardAt']
    assert_operator Time.zone.parse(response.parsed_body['dailyReward']['nextRewardAt']), :>, Time.zone.now

    # Preferences & Settings
    assert_equal false, response.parsed_body['preferences']['developer']
  end
end
