# frozen_string_literal: true

class CreateMonsters < ActiveRecord::Migration[7.0]
  def change
    create_table :monsters do |t|
      t.string :name,           null: false, index: { unique: true }
      t.string :description,    null: false
      t.integer :level,         null: false
      t.string :classification, null: false
      t.boolean :auto_spawn,    null: false, default: true
      t.text :tags,             array: true, default: []
      t.timestamps
    end
  end
end
