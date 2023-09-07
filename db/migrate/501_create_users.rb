# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :auth0_user_id, null: false, index: { unique: true }
      t.json :auth0_user_data
      t.hstore :preferences
      t.integer :xp,           default: 0
      t.integer :level,        default: 1
      t.integer :gold,         default: 10
      t.text :achievements,    array: true, default: []
      t.text :access_token
      t.belongs_to :inventory, null: false, index: { unique: true }
      t.timestamp :access_token_expires_at
      t.timestamps
    end
  end
end
