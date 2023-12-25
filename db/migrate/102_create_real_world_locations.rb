# frozen_string_literal: true

class CreateRealWorldLocations < ActiveRecord::Migration[7.0]
  def change
    create_table :real_world_locations do |t|
      # t.string    :name,        null: false
      t.string    :type,        null: false
      t.string    :ext_id,      null: true, index: { unique: true }
      t.st_point  :coordinates, geographic: true, index: { unique: true }
      t.jsonb     :tags
      t.timestamps
    end
  end
end
