  class InventoryItemSerializer < ActiveModel::Serializer
  attributes :id, :item_id, :item_type, :name, :rarity, :bonuses, :equipable, :two_handed, :is_equipped

  def item_type
    object.item.type
  end
  def name
    object.item.name
  end
  def rarity
    object.item.rarity
  end
  def bonuses
    object.item.bonuses
  end
  def equipable
    true
  end
  def two_handed
    object.item.two_handed
  end
end
