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

  test 'should edit my user' do
    new_name = 'Princess Bubblegum'

    patch '/api/v1/users/me', headers: generate_headers, params: {
      user: {
        name: new_name,
      },
    }
    assert_response :ok
    assert_equal new_name, response.parsed_body['name']
  end

  test 'should get experience table' do
    test_level = 42

    get '/api/v1/users/experience_table', headers: generate_headers
    assert_response :ok
    assert_equal 0, response.parsed_body[0]
    assert_equal User.total_xp_needed_for_level(test_level), response.parsed_body[test_level - 1]
  end
end
