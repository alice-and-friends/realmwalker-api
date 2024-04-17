# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users, id: :uuid do |t|
      # Account
      t.string    :auth0_user_id,         null: false, index: { unique: true }
      t.json      :auth0_user_data
      t.json      :preferences
      t.text      :access_token
      t.timestamp :access_token_expires_at

      # Game
      t.string    :display_name
      t.integer   :xp,                    default: 0
      t.integer   :level,                 default: 1
      t.text      :achievements,          array: true, default: []
      t.text      :discovered_runestones, array: true, default: []
      t.timestamp :reward_claimed_at
      t.integer   :reward_streak,         null: false, default: 0
      t.timestamps
    end
  end
end
