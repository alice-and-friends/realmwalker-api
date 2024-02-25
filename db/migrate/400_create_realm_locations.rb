# frozen_string_literal: true

class CreateRealmLocations < ActiveRecord::Migration[7.0]
  def change
    create_table :realm_locations do |t|

      # ALL
      t.string :type # required for inheritance
      t.belongs_to :real_world_location, null: false, index: { unique: true }
      t.st_point :coordinates, geographic: true, limit: { srid: 4326 }
      t.string :region, null: false
      t.column :name, :string
      t.timestamps

      # BASE (user-owned location)
      t.references :owner, index: { unique: true }, foreign_key: { to_table: :users }, on_delete: :cascade

      # NPC
      t.column :species, :string
      t.column :gender, :string, limit: 1
      t.column :role, :string
      t.string :shop_type
      t.references :portrait, foreign_key: true

      # Dungeon
      t.column :status, :string
      t.column :level, :integer
      t.references :monster
      t.column :defeated_at, :datetime
      t.references :defeated_by, foreign_key: { to_table: :users }

      # RunestonesHelper
      t.string :runestone_id
    end

    # Coordinates GIST index
    add_index :realm_locations, :coordinates, using: :gist
  end
end
