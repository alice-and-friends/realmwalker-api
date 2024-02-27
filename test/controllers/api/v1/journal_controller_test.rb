# frozen_string_literal: true

require 'test_helper'

class Api::V1::JournalControllerTest < ActionDispatch::IntegrationTest

  test 'runestone progress in journal' do
    runestone = RunestonesHelper.first
    user = users(:jane_doe)
    user.discover_runestone(runestone.id)

    get '/api/v1/journal/runestones',
          headers: generate_headers

    assert_equal 200, status
    assert_equal 1, response.parsed_body['discoveredCount']
    assert_equal RunestonesHelper.count - 1, response.parsed_body['undiscoveredCount']
    item = response.parsed_body['discoveredRunestones'].first
    assert item['name'].present?
  end
end
