# frozen_string_literal: true

class RenewableSerializer < RealmLocationSerializer
  attribute :next_growth_at
  attribute :inventory

  def inventory
    ActiveModelSerializers::SerializableResource.new(object.inventory, serializer: InventorySerializer)
  end
end
