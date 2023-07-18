class CreateDungeons < ActiveRecord::Migration[7.0]
  def change
    create_table :dungeons do |t|
      t.belongs_to :real_world_location
      t.column :status, :integer, default: 1
      t.column :level, :integer, default: 1
      t.references :monster
      t.column :defeated_at, :datetime
      t.references :defeated_by, index: true, foreign_key: { to_table: :users }, optional: true
      t.timestamps
    end
  end
end
