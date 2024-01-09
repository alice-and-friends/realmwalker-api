# frozen_string_literal: true

class CreateBases < ActiveRecord::Migration[7.0]
  def change
    create_table :bases do |t|
      t.belongs_to :user, null: false, index: { unique: true }
      t.belongs_to :real_world_location, null: false
      t.st_point :coordinates, geographic: true, index: { unique: true }

      t.timestamps
    end
  end
end
