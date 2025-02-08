# frozen_string_literal: true

class CreateInventoryTransactions < ActiveRecord::Migration[7.0]
  def change
    create_table :inventory_transactions do |t|
      t.string :description, null: false
      t.jsonb :create_items, default: [] # Store full item details instead of just IDs
      t.jsonb :transfer_items, default: []
      t.jsonb :destroy_items, default: []
      t.jsonb :add_gold, default: []
      t.jsonb :transfer_gold, default: []
      t.jsonb :subtract_gold, default: []
      t.string :status, null: false, default: 'staged'
      t.timestamps
    end
  end
end
