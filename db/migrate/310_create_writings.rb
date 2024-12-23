# frozen_string_literal: true

class CreateWritings < ActiveRecord::Migration[7.0]
  def change
    create_table :writings do |t|
      t.string :title, null: false, default: ''
      t.string :author_name, null: false, default: ''
      t.text :body, null: false, default: ''
      t.references :author, null: true, foreign_key: { to_table: :users }, on_delete: :nullify, type: :uuid
      t.boolean :core_content, null: false, default: false
      t.timestamps
    end
  end
end
