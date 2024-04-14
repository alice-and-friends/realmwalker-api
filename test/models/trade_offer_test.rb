# frozen_string_literal: true

require 'test_helper'

class TradeOfferTest < ActiveSupport::TestCase
  test 'there are trade offers in the test database' do
    assert_operator TradeOffer.count, :>, 0
  end

  test 'validates against infinite money exploit' do
    item = Item.last
    trade_offer_list_a = TradeOfferList.create(name: 'Test')
    trade_offer_list_b = TradeOfferList.create(name: 'Test')

    # With these trade offers, the player could buy and sell items repeatedly and generate infinite money
    TradeOffer.create!(trade_offer_list: trade_offer_list_a, item: item, sell_offer: 10_000_000)
    trade_offer = TradeOffer.create!(trade_offer_list: trade_offer_list_b, item: item, buy_offer: 10_000_001)

    assert_not trade_offer.valid?
    assert_not_nil trade_offer.errors
    assert_includes trade_offer.errors.to_a, 'Infinite money exploit'
  end
end
