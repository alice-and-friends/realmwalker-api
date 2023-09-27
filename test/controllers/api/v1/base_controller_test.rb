# frozen_string_literal: true

require 'test_helper'

class Api::V1::BaseControllerTest < ActionDispatch::IntegrationTest
  test 'should create base' do
    post '/api/v1/base', headers: generate_headers
    assert_response :created
  end
  # test 'should refuse to create second base' do
  #   users(:jane_doe).construct_base_at(generate_test_user_location)
  #   post '/api/v1/base', headers: generate_headers
  #   assert_response :forbidden
  # end
end
