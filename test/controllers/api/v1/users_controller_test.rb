# frozen_string_literal: true

require 'test_helper'

class Api::V1::BaseControllerTest < ActionDispatch::IntegrationTest
  test 'should get my user' do
    api_user = users(:jane_doe)
    get '/api/v1/users/me', headers: generate_headers
    assert_response :ok
    assert_equal api_user.id, response.parsed_body['id']
    assert_equal api_user.name, response.parsed_body['name']
    assert_equal false, response.parsed_body['preferences']['developer']
  end
end
