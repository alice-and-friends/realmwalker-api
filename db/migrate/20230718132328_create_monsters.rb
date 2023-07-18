class CreateMonsters < ActiveRecord::Migration[7.0]
  def change
    create_table :monsters do |t|
      t.string :name,         null: false
      t.string :description,  null: false
      t.integer :level,        null: false
      t.timestamps
    end
  end
end
