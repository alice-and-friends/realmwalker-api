# frozen_string_literal: true

require 'test_helper'

class Api::V1::CompendiumControllerTest < ActionDispatch::IntegrationTest
  test 'get list of monsters' do
    get '/api/v1/compendium/monsters', headers: generate_headers
    assert_equal 200, status
    assert_not response.parsed_body.empty?
  end

  test 'get list of items' do
    get '/api/v1/compendium/items', headers: generate_headers
    assert_equal 200, status
    assert_not response.parsed_body.empty?
  end
end
