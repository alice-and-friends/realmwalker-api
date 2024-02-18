# frozen_string_literal: true

class CreateRealWorldLocations < ActiveRecord::Migration[7.0]
  def change
    create_table :real_world_locations do |t|
      t.string    :type,        null: false
      t.string    :ext_id,      null: true, index: { unique: true } # Can be null for user-generated locations
      t.st_point  :coordinates, geographic: true, limit: { srid: 4326 }
      t.string    :region,      null: false
      t.float     :latitude,    null: false
      t.float     :longitude,   null: false
      t.jsonb     :tags
      t.string    :source_file
      t.integer   :relevance,   null: false, default: 0
      t.timestamps
    end

    # Coordinates GIST index
    add_index :real_world_locations, :coordinates, using: :gist

    # Add a composite unique index on the latitude and longitude columns
    add_index :real_world_locations, %i[latitude longitude], unique: true
  end
end
