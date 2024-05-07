# frozen_string_literal: true

class Renewable < RealmLocation
  RENEWABLE_TYPES = %w[flower_forest mine].freeze
  RENEWABLE_ITEMS = {
    'flower_forest' => [
      'Hatchet',
      'Small Emerald',
      'Present',
      'Noble Armor',
    ],
    'mine' => [
      'Hatchet',
      'Small Emerald',
      'Present',
      'Noble Armor',
    ],
  }.freeze
  MAX_ITEMS = 6

  alias_attribute :renewable_type, :sub_type

  validates :renewable_type, inclusion: { in: RENEWABLE_TYPES }

  before_validation :set_region_and_coordinates!, on: :create
  before_validation :set_renewable_type!
  after_create { Inventory.create!(realm_location: self) }

  def item_table
    raise "No items specified for renewable type #{renewable_type}" unless RENEWABLE_ITEMS[renewable_type]

    items = Item.where(name: RENEWABLE_ITEMS[renewable_type])
    raise "No items found for renewable type #{renewable_type}" if items.empty?

    items
  end

  def grow!
    item = nil

    # Bias toward increasing the existing items, instead of adding more items
    if rand(0..1).positive?
      growable_item_ids = inventory_items.pluck(:item_id) & item_table.pluck(:id)

      if growable_item_ids.count.positive?
        item = inventory_items.create!(item: Item.find(growable_item_ids.sample))
      end
    end

    # Add a new item if not done above
    inventory_items.create!(item: item_table.sample) if item.nil?

    inventory_items.joins(:item).pluck('items.name')
  end

  private

  def set_renewable_type!
    self.renewable_type = RENEWABLE_TYPES.sample
  end
end
