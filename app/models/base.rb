# frozen_string_literal: true

class Base < RealmLocation
  belongs_to :user
  has_one :inventory, dependent: :destroy
  after_create { self.inventory = Inventory.create!(base: self) }
  delegate :inventory_items, to: :inventory

  def name
    "#{user.name}'s base"
  end
end
