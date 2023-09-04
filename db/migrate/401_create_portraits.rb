# frozen_string_literal: true

class CreatePortraits < ActiveRecord::Migration[7.0]
  def change
    create_table :portraits do |t|
      t.column :name, :string
      t.column :species, :string, array: true, default: []
      t.column :genders, :string, array: true, default: []
      t.column :groups, :string, array: true, default: []
      t.timestamps
    end
  end
end
