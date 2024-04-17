# frozen_string_literal: true

class CreateTradeOffersAndLists < ActiveRecord::Migration[7.0]
  def change
    create_table :trade_offer_lists do |t|
      t.string :name, null: false
      t.timestamps
    end
    create_table :trade_offers do |t|
      t.references :item, null: true, foreign_key: true, on_delete: :cascade
      t.integer :buy_offer
      t.integer :sell_offer
      t.belongs_to :trade_offer_list
      t.timestamps
    end
    # create_table :trade_offer_lists_trade_offers, id: false do |t|
    #   t.belongs_to :trade_offer_list
    #   t.belongs_to :trade_offer
    # end
    create_table :npcs_trade_offer_lists, id: false do |t|
      t.references :npc, type: :uuid, index: true, foreign_key: { to_table: :realm_locations }
      t.belongs_to :trade_offer_list
    end
  end
end
