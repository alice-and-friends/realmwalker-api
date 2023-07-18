class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :auth0_user_id
      t.json :auth0_user_data
      t.hstore :preferences

      t.timestamps
    end
  end
end