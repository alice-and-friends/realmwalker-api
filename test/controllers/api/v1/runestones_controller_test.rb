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
    assert_equal false, response.parsed_body['discovered']
  end
  test 'should discover runestone' do
    runestone = Runestone.first
    2.times do # Make sure we handle repeated requests gracefully
      post "/api/v1/runestones/#{runestone.id}/add_to_journal", headers: generate_headers
      assert_response :ok
      assert_equal runestone.id, response.parsed_body['id']
      assert_equal runestone.name, response.parsed_body['name']
      assert_equal runestone.text, response.parsed_body['text']
      assert_equal true, response.parsed_body['discovered']
    end
  end
  test 'should get discovered runestone' do
    runestone = Runestone.first
    user = users(:jane_doe)
    user.discover_runestone runestone.runestone_id
    get "/api/v1/runestones/#{runestone.id}", headers: generate_headers
    assert_response :ok
    assert_equal runestone.id, response.parsed_body['id']
    assert_equal runestone.name, response.parsed_body['name']
    assert_equal runestone.text, response.parsed_body['text']
    assert_equal true, response.parsed_body['discovered']
  end
end
