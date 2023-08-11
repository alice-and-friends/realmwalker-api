class CreateInventoryItems < ActiveRecord::Migration[7.0]
  def change
    create_table :inventory_items do |t|
      t.references :user, foreign_key: true, on_delete: :cascade
      t.references :item, foreign_key: true
      t.boolean :is_equipped, default: false
      t.timestamps
    end
  end
end
