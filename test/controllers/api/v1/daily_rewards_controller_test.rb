# frozen_string_literal: true

require 'test_helper'

class Api::V1::DailyRewardsControllerTest < ActionDispatch::IntegrationTest
  test 'should get daily reward info' do
    get '/api/v1/daily_rewards', headers: generate_headers
    assert_response :ok

    assert response.parsed_body['claimable']
    assert_instance_of Integer, response.parsed_body['streak']
    assert response.parsed_body['nextRewardAt']
    assert_operator Time.zone.parse(response.parsed_body['nextRewardAt']), :>, Time.zone.now
  end
  test 'should claim daily reward' do
    post '/api/v1/daily_rewards/claim', headers: generate_headers
    assert_response :ok

    assert_not response.parsed_body['claimable']
    assert response.parsed_body['streak']
    assert_operator Time.zone.parse(response.parsed_body['nextRewardAt']), :>, Time.zone.now
  end
end
