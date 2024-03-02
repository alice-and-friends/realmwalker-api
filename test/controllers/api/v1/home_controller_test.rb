# frozen_string_literal: true

require 'test_helper'

class Api::V1::HomeControllerTest < ActionDispatch::IntegrationTest
  test 'get home' do
    get '/api/v1/home', headers: generate_headers
    assert_equal 200, status
    assert_not response.parsed_body['serverTime'].blank?
    assert_not response.parsed_body['events'].nil?
  end
end
