class CreateNpcs < ActiveRecord::Migration[7.0]
  def change
    create_table :npcs do |t|
      t.belongs_to :real_world_location
      t.column :name, :string
      t.timestamps
    end
  end
end
