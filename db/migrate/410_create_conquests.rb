# frozen_string_literal: true

class CreateConquests < ActiveRecord::Migration[7.0]
  def change
    # Use this table to track which users defeated which dungeons
    create_table :conquests do |t|
      t.references :realm_location, null: true, foreign_key: { to_table: :realm_locations }, type: :uuid
      t.string :realm_location_type, null: false
      t.references :monster, null: true, foreign_key: { to_table: :monsters }
      t.references :user, null: false, foreign_key: { to_table: :users }, type: :uuid

      t.timestamps
    end
  end
end
