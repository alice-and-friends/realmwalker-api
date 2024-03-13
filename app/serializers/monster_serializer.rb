# frozen_string_literal: true

class MonsterSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :level, :classification, :tags
  attribute :items, if: :compendium?

  def compendium?
    @instance_options[:compendium]
  end

  def items
    ActiveModelSerializers::SerializableResource.new(object.lootable_items.order(:type, :name), each_serializer: ItemSerializer)
  end
end
