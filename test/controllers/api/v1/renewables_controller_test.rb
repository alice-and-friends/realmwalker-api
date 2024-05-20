# frozen_string_literal: true

require 'test_helper'

class Api::V1::RenewablesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:jane_doe)
    @renewable = generate_test_renewable
    @renewable.fill!
  end
  test 'should get renewable with inventory' do
    get "/api/v1/renewables/#{@renewable.id}", headers: generate_headers
    assert_response :ok
    assert_not_nil response.parsed_body['inventory']
    assert_kind_of Array, response.parsed_body['inventory']['items']
  end
  test 'renewable growth is forecasted' do
    # Full inventory should not have forecasted growth
    get "/api/v1/renewables/#{@renewable.id}", headers: generate_headers
    assert_not response.parsed_body['nextGrowthAt']

    # Empty inventory should have forecasted growth
    @renewable.inventory_items.destroy_all
    get "/api/v1/renewables/#{@renewable.id}", headers: generate_headers
    assert response.parsed_body['nextGrowthAt']
  end
  test 'should take all inventory items from renewable' do
    collectible_item = @renewable.inventory_items.first
    post "/api/v1/renewables/#{@renewable.id}/collect_all", headers: generate_headers
    assert_response :ok
    assert_equal @user.inventory.id, collectible_item.reload.inventory_id
    assert_not_nil response.parsed_body['inventory']
    assert_empty response.parsed_body['inventory']['items']
  end
  test 'handle multiple collect all requests' do
    post "/api/v1/renewables/#{@renewable.id}/collect_all", headers: generate_headers
    assert_response :ok
    assert_not_nil response.parsed_body['inventory']
    assert_kind_of Array, response.parsed_body['inventory']['items']
    post "/api/v1/renewables/#{@renewable.id}/collect_all", headers: generate_headers
    assert_response :gone
    assert_not_nil response.parsed_body['inventory']
    assert_kind_of Array, response.parsed_body['inventory']['items']
  end
end
