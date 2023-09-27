# frozen_string_literal: true

class InventoryItem < ApplicationRecord
  belongs_to :inventory
  belongs_to :item

  scope :alphabetical, -> { joins(:item).order('items.name': :asc) }
  scope :ordered, -> { joins(:item).order(is_equipped: :desc, 'items.name': :asc) }

  before_save :unequip!, if: :will_save_change_to_inventory_id?

  def equipped?
    is_equipped
  end

  delegate :owner, to: :inventory

  private

  def unequip!
    self.is_equipped = false
  end
end
