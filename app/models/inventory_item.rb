# frozen_string_literal: true

class InventoryItem < ApplicationRecord
  belongs_to :user
  belongs_to :item

  scope :alphabetical, -> { joins(:item).order('items.name': :asc) }
  scope :ordered, -> { joins(:item).order(is_equipped: :desc, 'items.name': :asc) }

  def equipped?
    is_equipped
  end
end
