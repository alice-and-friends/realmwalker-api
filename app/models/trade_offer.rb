# frozen_string_literal: true

class TradeOffer < ApplicationRecord
  belongs_to :item
  has_and_belongs_to_many :trade_offer_lists, join_table: 'trade_offer_lists_trade_offers'
  has_many :npcs, through: :trade_offer_lists

  validate :tradable

  private

  def tradable
    Errors.add(:base, 'Must have one of: buy_offer, sell_offer') if buy_offer.nil? && sell_offer.nil?
  end
end
