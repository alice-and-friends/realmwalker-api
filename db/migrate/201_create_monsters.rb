# frozen_string_literal: true

class CreateMonsters < ActiveRecord::Migration[7.0]
  def change
    create_table :monsters do |t|
      t.string :name,           null: false
      t.string :description,    null: false
      t.integer :level,         null: false
      t.string :classification, null: false
      t.text :tags,             array: true, default: []
      t.timestamps
    end
  end
end
