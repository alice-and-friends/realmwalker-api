# frozen_string_literal: true

require 'test_helper'

class Api::V1::LeyLinesControllerTest < ActionDispatch::IntegrationTest
  # test 'should get ley line' do
  #   location = LeyLine.first
  #   throw('no ley line available for test') if location.nil?
  #
  #   get "/api/v1/ley_lines/#{location.id}", headers: generate_headers
  #   assert_equal 200, status
  #   assert_equal location.id, response.parsed_body['id']
  # end
  # test 'should capture ley line' do
  #   location = LeyLine.first
  #   throw('no ley line available for test') if location.nil?
  #
  #   post "/api/v1/ley_lines/#{location.id}/capture", headers: generate_headers
  #   assert_equal 200, status
  #   assert_equal location.id, response.parsed_body['id']
  #
  #   jane = users(:jane_doe)
  #   assert_equal jane.name, response.parsed_body['capturedBy'][0]['name']
  #   assert_safe_user_object response.parsed_body['capturedBy'][0]
  # end
end
