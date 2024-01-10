# frozen_string_literal: true

class CreateNpcs < ActiveRecord::Migration[7.0]
  def change
    create_table :npcs do |t|
      t.belongs_to :real_world_location
      t.st_point :coordinates, geographic: true
      t.column :name, :string
      t.column :species, :string
      t.column :gender, :string, limit: 1
      t.column :role, :string
      t.string :shop_type
      t.references :portrait, null: true, foreign_key: true
      t.timestamps
    end

    # Coordinates GIST index
    execute <<-SQL
      ALTER TABLE npcs ADD EXCLUDE USING gist (coordinates WITH &&);
    SQL
  end
end
