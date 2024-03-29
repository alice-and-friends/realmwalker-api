# frozen_string_literal: true

require 'test_helper'

class Api::V1::HomeControllerTest < ActionDispatch::IntegrationTest
  test 'get home' do
    get '/api/v1/home', headers: generate_headers
    assert_equal 200, status
    assert response.parsed_body['serverTime']
    assert_instance_of Array, response.parsed_body['events']['active']
    assert_instance_of Array, response.parsed_body['events']['upcoming']
  end
end
