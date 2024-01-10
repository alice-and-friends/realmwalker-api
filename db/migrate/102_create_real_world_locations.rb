# frozen_string_literal: true

class CreateRealWorldLocations < ActiveRecord::Migration[7.0]
  def change
    create_table :real_world_locations do |t|
      # t.string    :name,        null: false
      t.string    :type,        null: false
      t.string    :ext_id,      null: true, index: { unique: true }
      t.st_point  :coordinates, geographic: true
      t.jsonb     :tags
      t.timestamps
    end

    # Coordinates GIST index
    execute <<-SQL
      ALTER TABLE real_world_locations ADD EXCLUDE USING gist (coordinates WITH &&);
    SQL
  end
end
