# frozen_string_literal: true

class CreateBattles < ActiveRecord::Migration[7.0]
  def change
    # Use this table to track which users defeated which dungeons
    create_table :battles do |t|
      t.references :monster, null: true, foreign_key: { to_table: :monsters }
      t.references :player, foreign_key: { to_table: :users }, null: false, type: :uuid
      t.references :opponent, polymorphic: true, null: false, type: :uuid
      t.string :status, null: false

      t.timestamps
    end

    add_index :battles, :status
    add_index :battles, [:player_id, :status]
    add_index :battles, [:status, :updated_at]
  end
end
