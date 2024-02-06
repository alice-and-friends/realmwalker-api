# frozen_string_literal: true

class CreateSpooks < ActiveRecord::Migration[7.0]
  def change
    create_table :spooks do |t|
      t.references :npc, null: false, foreign_key: { to_table: :realm_locations }
      t.references :dungeon, null: false, foreign_key: { to_table: :realm_locations }

      t.timestamps
    end
  end
end
