# frozen_string_literal: true

class CreateInventoryItems < ActiveRecord::Migration[7.0]
  def change
    create_table :inventory_items do |t|
      t.references :inventory, null: false, foreign_key: true, on_delete: :cascade
      t.references :item, null: false, foreign_key: true, on_delete: :cascade
      t.references :writing, null: true, foreign_key: true, on_delete: :cascade
      t.boolean :is_equipped, null: false, default: false
      t.timestamps
    end
  end
end
