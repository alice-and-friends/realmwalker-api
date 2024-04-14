# frozen_string_literal: true

require 'test_helper'

class NpcTest < ActiveSupport::TestCase
  test 'there are npcs in the test database' do
    assert_operator Npc.count, :>, 0
  end
  test 'can generate npc' do
    initial_count = Npc.count
    Npc.create!(
      role: 'shopkeeper',
      shop_type: Npc::SHOP_TYPES.first,
      trade_offer_lists: [TradeOfferList.create],
      real_world_location: RealWorldLocation.available.first,
    )
    assert_operator Npc.count, :>, initial_count
  end
  test "can't create shopkeeper npc without a valid shop type" do
    invalid_npc = Npc.new(
      role: 'shopkeeper',
      shop_type: 'invalid shop type',
      trade_offer_lists: [TradeOfferList.create],
      real_world_location: RealWorldLocation.available.first,
    )
    assert_not invalid_npc.valid?
  end
  test 'new npc should receive gender and name' do
    new_npc = Npc.create!(
      role: 'shopkeeper',
      shop_type: Npc::SHOP_TYPES.first,
      trade_offer_lists: [TradeOfferList.create],
      real_world_location: RealWorldLocation.available.first,
    )
    assert_not_empty new_npc.gender
    assert_not_empty new_npc.name
  end
  test 'should return a list of trade offers without duplicates' do
    ITEM = Item.first
    TRADE_OFFER = TradeOffer.create(item: ITEM, buy_offer: 500, sell_offer: 1000)
    LIST_1 = TradeOfferList.create(name: 'list_1', trade_offers: [TRADE_OFFER])
    LIST_2 = TradeOfferList.create(name: 'list_2', trade_offers: [TRADE_OFFER])
    NPC = Npc.create(name: 'arnold', role: 'shopkeeper', shop_type: Npc::SHOP_TYPES.first, trade_offer_lists: [LIST_1, LIST_2])
    assert_equal NPC.buy_offers.pluck(:item_id).uniq.count, NPC.buy_offers.pluck(:item_id).count
    assert_equal NPC.sell_offers.pluck(:item_id).uniq.count, NPC.sell_offers.pluck(:item_id).count
  end
  test 'different npcs trade different items' do
    WEDDING_RING = Item.find_by(name: 'Wedding Ring')
    SHORTSWORD = Item.find_by(name: 'Shortsword')
    ARMORER = Npc.find_by(role: 'shopkeeper', shop_type: 'armorer')
    JEWELLER = Npc.find_by(role: 'shopkeeper', shop_type: 'jeweller')
    assert WEDDING_RING.sold_by_npc? JEWELLER
    assert_not WEDDING_RING.sold_by_npc? ARMORER
    assert SHORTSWORD.sold_by_npc? ARMORER
    assert_not SHORTSWORD.sold_by_npc? JEWELLER
  end
end
