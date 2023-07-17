class CreateRealmLocations < ActiveRecord::Migration[7.0]
  def change
    create_table :realm_locations do |t|

      t.timestamps
    end
  end
end
