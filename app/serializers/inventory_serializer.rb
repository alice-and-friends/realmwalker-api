# frozen_string_literal: true

class InventorySerializer < ActiveModel::Serializer
  attributes :id, :gold, :items

  def items
    ActiveModelSerializers::SerializableResource.new(object.inventory_items.ordered, each_serializer: InventoryItemSerializer)
  end
end
