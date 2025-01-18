# frozen_string_literal: true

class CreateDungeonSearches < ActiveRecord::Migration[7.0]
  def change
    create_table :dungeon_searches do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :realm_location, null: false, foreign_key: { to_table: :realm_locations }, type: :uuid

      t.timestamps
    end

    add_index :dungeon_searches, [:user_id, :realm_location_id], unique: true
  end
end
