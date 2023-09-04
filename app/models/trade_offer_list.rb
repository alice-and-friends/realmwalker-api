# frozen_string_literal: true

class TradeOfferList < ApplicationRecord
  has_and_belongs_to_many :trade_offers, join_table: 'trade_offer_lists_trade_offers'
  has_and_belongs_to_many :npcs, join_table: 'npcs_trade_offer_lists'

  validates :name, presence: true
  before_validation :assign_name

  private

  def assign_name
    self.name = (0...8).map { ('a'..'z').to_a[rand(26)] }.join if name.blank?
  end
end
