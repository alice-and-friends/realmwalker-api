# frozen_string_literal: true

class InventoryItemSerializer < ActiveModel::Serializer
  attributes :id, :item_id, :item_type, :name, :icon, :rarity, :bonuses, :equipable, :two_handed, :equipped

  def item_type
    object.item.type
  end

  def name
    object.item.name
  end

  def icon
    object.item.icon
  end

  def rarity
    object.item.rarity
  end

  def bonuses
    object.item.bonuses
  end

  def equipable
    object.item.equipable?
  end

  def two_handed
    object.item.two_handed
  end

  def equipped
    object.equipped?
  end
end
