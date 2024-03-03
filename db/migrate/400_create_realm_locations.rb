# frozen_string_literal: true

class CreateRealmLocations < ActiveRecord::Migration[7.0]
  def change
    create_table :realm_locations do |t|
      # ALL
      t.string :type # required for inheritance
      t.belongs_to :real_world_location, null: false, index: { unique: true }
      t.st_point :coordinates, geographic: true, limit: { srid: 4326 }
      t.string :region, null: false
      t.string :name
      t.timestamps

      # BASE (user-owned location)
      t.references :owner, index: { unique: true }, foreign_key: { to_table: :users }, on_delete: :cascade

      # NPC
      t.string :species
      t.string :gender, limit: 1
      t.string :role
      t.string :shop_type
      t.references :portrait, foreign_key: true

      # Dungeon
      t.string :status
      t.integer :level
      t.references :monster
      t.datetime :defeated_at
      t.string :expiry_job_id
      t.datetime :expires_at

      # RunestonesHelper
      t.string :runestone_id
    end

    # Coordinates GIST index
    add_index :realm_locations, :coordinates, using: :gist

    # Use this table to track which users defeated which dungeons
    create_table :conquests do |t|
      t.references :dungeon, null: false, foreign_key: { to_table: :realm_locations }
      t.references :user, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
