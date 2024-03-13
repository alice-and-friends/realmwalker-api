# frozen_string_literal: true

class ItemSerializer < ActiveModel::Serializer
  attributes :id, :type, :name, :icon, :rarity, :bonuses, :equipable, :two_handed, :drop_max_amount
  attribute :dropped_by, if: :compendium?
  attribute :value, if: :compendium?

  def compendium?
    @instance_options[:compendium]
  end

  def equipable
    object.equipable?
  end

  def dropped_by
    ActiveModelSerializers::SerializableResource.new(object.monsters.order(:level), each_serializer: MonsterSerializer)
  end
end
