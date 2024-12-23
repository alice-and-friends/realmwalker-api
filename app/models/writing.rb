# frozen_string_literal: true

class Writing < ApplicationRecord
  belongs_to :author, class_name: 'User', optional: true
  belongs_to :inventory_item, optional: true

  before_destroy :stop_destroy

  private

  def stop_destroy
    if core_content
      errors.add(:base, :undestroyable, message: "can't destroy core content")
      throw :abort
    elsif InventoryItem.exists?(writing_id: id)
      errors.add(:base, :undestroyable, message: "can't destroy writing attached to an item")
      throw :abort
    end
  end
end
