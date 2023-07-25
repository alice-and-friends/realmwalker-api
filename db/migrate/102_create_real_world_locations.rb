class CreateRealWorldLocations < ActiveRecord::Migration[7.0]
  def change
    create_table :real_world_locations do |t|
      t.string  :name,        null: false
      t.string  :type,        null: false
      t.string  :ext_id,      null: false
      t.point   :coordinates, null: false
      t.timestamps
    end
  end
end
