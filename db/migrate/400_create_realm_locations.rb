# frozen_string_literal: true

class CreateRealmLocations < ActiveRecord::Migration[7.0]
  def change
    create_table :realm_locations do |t|

      # ALL
      t.string :type # required for inheritance
      t.belongs_to :real_world_location, null: false, index: { unique: true }
      t.st_point :coordinates, geographic: true
      t.timestamps

      # BASE
      t.belongs_to :user, index: { unique: true }

      # NPC
      t.column :name, :string
      t.column :species, :string
      t.column :gender, :string, limit: 1
      t.column :role, :string
      t.string :shop_type
      t.references :portrait, null: true, foreign_key: true

      # Dungeon
      t.column :status, :string
      t.column :level, :integer
      t.references :monster
      t.column :defeated_at, :datetime
      t.references :defeated_by, index: true, foreign_key: { to_table: :users }, optional: true
    end

    # Coordinates GIST index
    add_index :realm_locations, :coordinates, using: :gist
  end
end
