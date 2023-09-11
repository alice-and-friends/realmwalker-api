# frozen_string_literal: true

class CreateInventories < ActiveRecord::Migration[7.0]
  def change
    create_table :inventories do |t|
      t.belongs_to :user, null: true, index: { unique: true }

      t.timestamps
    end
  end
end
