class SetEquippedSerializer < ActiveModel::Serializer
  attributes :equipped, :unequip_items, :inventory
end
