# frozen_string_literal: true

class CreateRealWorldLocations < ActiveRecord::Migration[7.0]
  def change
    create_table :real_world_locations do |t|
      # t.string    :name,        null: false
      t.string    :type,        null: false
      t.string    :ext_id,      null: true, index: { unique: true }
      t.st_point  :coordinates, geographic: true
      t.float     :latitude     # Add latitude column
      t.float     :longitude    # Add longitude column
      t.jsonb     :tags
      t.string    :source_file
      t.timestamps
    end

    # Coordinates GIST index
    add_index :real_world_locations, :coordinates, using: :gist

    # Add a composite unique index on the latitude and longitude columns
    add_index :real_world_locations, [:latitude, :longitude], unique: true
  end
end
