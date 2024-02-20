# frozen_string_literal: true

class CreateItems < ActiveRecord::Migration[7.0]
  def change
    create_table :items do |t|
      t.string :name,                           null: false, index: { unique: true }
      t.string :type,                           null: false
      t.string :icon,                           null: false

      # Obtainability
      t.string :rarity,                         null: false
      t.string :dropped_by_classification,      array: true, default: [] # TODO: Field name should be plural
      t.integer :dropped_by_level
      t.integer :drop_max_amount

      # Equipment
      t.boolean :two_handed,                    null: false, default: false
      t.integer :attack_bonus,                  default: 0, limit: 1
      t.integer :defense_bonus,                 default: 0, limit: 1
      t.string :classification_bonus
      t.integer :classification_attack_bonus,   default: 0, limit: 1
      t.integer :classification_defense_bonus,  default: 0, limit: 1
      t.float :xp_bonus,                        default: 0.0
      t.float :loot_bonus,                      default: 0.0

      t.timestamps
    end
  end
end
