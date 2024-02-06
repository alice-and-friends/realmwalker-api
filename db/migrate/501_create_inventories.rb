# frozen_string_literal: true

class CreateInventories < ActiveRecord::Migration[7.0]
  def change
    create_table :inventories do |t|
      t.belongs_to :user, null: true, index: { unique: true }
      t.belongs_to :realm_location, null: true, index: { unique: true }
      t.integer :gold, null: false, default: 0

      t.timestamps
    end
  end
end
