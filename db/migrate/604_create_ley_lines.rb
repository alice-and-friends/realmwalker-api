# frozen_string_literal: true

class CreateLeyLines < ActiveRecord::Migration[7.0]
  def change
    create_table :ley_lines do |t|
      t.belongs_to :real_world_location
      t.st_point :coordinates, geographic: true
      # t.column :status, :integer, default: 1
      t.timestamps
    end

    # Coordinates GIST index
    execute <<-SQL
      ALTER TABLE battlefields ADD EXCLUDE USING gist (coordinates WITH &&);
    SQL
  end
end
