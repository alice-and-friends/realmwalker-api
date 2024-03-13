# frozen_string_literal: true

class CreateMonsterItems < ActiveRecord::Migration[7.0]
  def change
    create_table :monster_items do |t|
      t.references :monster, null: false, foreign_key: true
      t.references :item, null: false, foreign_key: true

      t.timestamps
    end

    # Composite unique index
    add_index :monster_items, %i[monster_id item_id], unique: true
  end
end
