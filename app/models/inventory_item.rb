# frozen_string_literal: true

class InventoryItem < ApplicationRecord
  belongs_to :inventory
  belongs_to :item
  belongs_to :writing, optional: true

  before_save :unequip!, if: :will_save_change_to_inventory_id?
  after_destroy :destroy_writing

  scope :alphabetical, -> { joins(:item).order('items.name': :asc) }
  scope :ordered, -> { joins(:item).order(is_equipped: :desc, 'items.name': :asc) }

  def equipped?
    is_equipped
  end

  delegate :owner, to: :inventory
  delegate :name, to: :item
  delegate :actions, to: :item

  private

  def unequip!
    self.is_equipped = false
  end

  def destroy_writing
    return if writing.blank?

    begin
      writing.destroy!
    rescue ActiveRecord::RecordNotDestroyed
      # this is fine, probably means the writing is used for something else
    end
  end
end
