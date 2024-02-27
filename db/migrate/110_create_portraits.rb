# frozen_string_literal: true

class CreatePortraits < ActiveRecord::Migration[7.0]
  def change
    create_table :portraits do |t|
      t.string :name
      t.string :species, array: true, default: []
      t.string :genders, array: true, default: []
      t.string :groups, array: true, default: []
      t.timestamps
    end
  end
end
