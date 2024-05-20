# frozen_string_literal: true

require 'test_helper'

class Api::V1::RenewablesControllerTest < ActionDispatch::IntegrationTest
  test 'should get renewable' do
    renewable = generate_test_renewable
    get "/api/v1/renewables/#{renewable.id}", headers: generate_headers
    assert_response :ok
    assert_not_nil response.parsed_body['inventory']
    assert_kind_of Array, response.parsed_body['inventory']['items']
  end
end
