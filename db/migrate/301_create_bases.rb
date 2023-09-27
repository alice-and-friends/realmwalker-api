# frozen_string_literal: true

class CreateBases < ActiveRecord::Migration[7.0]
  def change
    create_table :bases do |t|
      t.belongs_to :user, null: false, index: { unique: true }
      t.belongs_to :real_world_location, null: false

      t.timestamps
    end
  end
end
