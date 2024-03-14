# frozen_string_literal: true

class TradeOffer < ApplicationRecord
  belongs_to :item
  belongs_to :trade_offer_list
  has_many :npcs, through: :trade_offer_list

  validate :tradable

  private

  def tradable
    Errors.add(:base, 'Must have one of: buy_offer, sell_offer') if buy_offer.nil? && sell_offer.nil?
  end
end
