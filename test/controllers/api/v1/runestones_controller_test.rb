# frozen_string_literal: true

require 'test_helper'

class Api::V1::RunestonesControllerTest < ActionDispatch::IntegrationTest
  test 'should get runestone' do
    runestone = Runestone.first
    get "/api/v1/runestones/#{runestone.id}", headers: generate_headers
    assert_response :ok
    assert_equal runestone.id, response.parsed_body['id']
    assert_equal runestone.name, response.parsed_body['name']
    assert_equal runestone.text, response.parsed_body['text']
  end
end
