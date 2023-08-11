class InventoryItem < ApplicationRecord
  belongs_to :user
  belongs_to :item

  scope :ordered, -> { joins(:item).order(is_equipped: :desc, "items.name": :asc) }

  def equipable?
    puts item.type, Item::item_types.armor
  end
end
