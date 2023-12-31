class CreateBattlefields < ActiveRecord::Migration[7.0]
  def change
    create_table :battlefields do |t|
      t.belongs_to :real_world_location
      t.belongs_to :dungeon
      t.column :status, :integer, default: 1
      t.timestamps
    end
  end
end
