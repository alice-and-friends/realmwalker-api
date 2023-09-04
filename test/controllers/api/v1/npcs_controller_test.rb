# frozen_string_literal: true

require 'test_helper'

class Api::V1::NpcsControllerTest < ActionDispatch::IntegrationTest
  test 'should get npc' do
    npc = Npc.first
    get "/api/v1/npcs/#{npc.id}"
    assert_equal 200, status
    assert_equal npc.id, response.parsed_body['id']
    assert_equal npc.role, response.parsed_body['role']
    assert_equal npc.name, response.parsed_body['name']
  end
end
