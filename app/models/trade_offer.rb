# frozen_string_literal: true

class TradeOffer < ApplicationRecord
  belongs_to :item
  belongs_to :trade_offer_list
  has_many :npcs, through: :trade_offer_list

  validate :must_be_tradable
  validate :must_not_be_exploitable

  private

  def must_be_tradable
    errors.add(:base, 'Must have one of: buy_offer, sell_offer') if buy_offer.nil? && sell_offer.nil?
  end

  # Make sure the item can't be sold for a higher price than it can be bought
  def must_not_be_exploitable
    highest_buy_offer = item.buy_offers.order(buy_offer: :desc).select(:buy_offer).pluck(:buy_offer).first
    return if highest_buy_offer.nil?

    lowest_sell_offer = item.sell_offers.order(sell_offer: :asc).select(:sell_offer).pluck(:sell_offer).first
    return if lowest_sell_offer.nil?

    errors.add(:base, 'Infinite money exploit') if lowest_sell_offer < highest_buy_offer
  end
end
