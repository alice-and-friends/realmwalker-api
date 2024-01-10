# frozen_string_literal: true

class CreateDungeons < ActiveRecord::Migration[7.0]
  def change
    create_table :dungeons do |t|
      t.belongs_to :real_world_location
      t.st_point :coordinates, geographic: true
      t.column :status, :integer, default: 1
      t.column :level, :integer, null: false
      t.references :monster
      t.column :defeated_at, :datetime
      t.references :defeated_by, index: true, foreign_key: { to_table: :users }, optional: true
      t.timestamps
    end

    # Coordinates GIST index
    execute <<-SQL
      ALTER TABLE dungeons ADD EXCLUDE USING gist (coordinates WITH &&);
    SQL
  end
end
