class CreateItems < ActiveRecord::Migration[7.0]
  def change
    create_table :items do |t|
      t.string :name,                           null: false
      t.string :type,                           null: false

      # Lootable?
      t.string :rarity,                         null: false
      t.string :dropped_by_classification,      array: true, default: []
      t.integer :dropped_by_level

      # Equipment?
      t.boolean :two_handed
      t.integer :attack_bonus,                  default: 0, limit: 1
      t.integer :defense_bonus,                 default: 0, limit: 1
      t.string :classification_bonus
      t.integer :classification_attack_bonus,   default: 0, limit: 1
      t.integer :classification_defense_bonus,  default: 0, limit: 1
      t.float :xp_bonus,                        default: 0.0
      t.float :loot_bonus,                      default: 0.0

      # Tradable?
      t.integer :npc_buy
      t.integer :npc_sell

      t.timestamps
    end
  end
end
