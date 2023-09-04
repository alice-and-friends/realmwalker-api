# frozen_string_literal: true

require 'test_helper'

class Api::V1::TradeOffersControllerTest < ActionDispatch::IntegrationTest
  test 'should sell leather armor to armorer' do
    user = User.first
    user.gain_item Item.find_by(name: 'Leather Armor')
    npc = Npc.find_by(role: 'shopkeeper', shop_type: 'armorer')
    trade_offer = npc.trade_offers.joins(:item).find_by('items.name': 'Leather Armor')
    post "/api/v1/npcs/#{npc.id}/trade_offers/#{trade_offer.id}/sell"
    assert_equal 200, status
  end
end
