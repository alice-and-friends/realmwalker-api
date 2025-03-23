# frozen_string_literal: true

class CreateBattleTurns < ActiveRecord::Migration[7.0]
  def change
    create_table :battle_turns do |t|
      t.references :battle, null: false, foreign_key: true, on_delete: :cascade
      t.integer    :sequence, null: false
      t.references :actor, polymorphic: true, null: false, type: :uuid # User or RealmLocation
      t.references :target, polymorphic: true, null: false, type: :uuid # User or RealmLocation
      t.string     :action, null: true # Example: "attack", "defend"
      t.integer    :damage, null: true
      t.string     :status, null: false

      t.timestamps
    end

    add_index :battle_turns, :action
    add_index :battle_turns, [:battle_id, :status]
    add_index :battle_turns, [:battle_id, :sequence], unique: true
    add_index :battle_turns, [:actor_id, :actor_type]
    add_index :battle_turns, [:target_id, :target_type]
  end
end
