# frozen_string_literal: true

class BaseSerializer < RealmLocationSerializer
  attributes :inventory

  def inventory
    ActiveModelSerializers::SerializableResource.new(object.inventory, serializer: InventorySerializer)
  end
end
