# frozen_string_literal: true

class Renewable < RealmLocation
  RENEWABLE_TYPES = %w[flower_forest mine].freeze
  RENEWABLE_ITEMS = {
    'flower_forest' => [
      # COMMON
      'Brown Mushroom',
      'Fire Mushroom',
      'Rose',
      'Fern',

      # RARE
      'Blood Herb',
      'Four-Leaf Clover',
    ],
    'mine' => [
      # COMMON
      # 'Wooden Key',
      'Iron Ore',

      # UNCOMMON
      # 'Silver Key',
      # 'Golden Key',
      'Small Diamond',
      'Small Emerald',
      'Small Ruby',
      'Small Sapphire',
      'Small Amethyst',
      'Small Topaz',
      'Ooze Divider',

      # RARE
      # 'Crystal Key',
      'Golem Repair Toolkit',
    ],
  }.freeze

  alias_attribute :renewable_type, :sub_type

  validates :renewable_type, inclusion: { in: RENEWABLE_TYPES }

  before_validation :set_region_and_coordinates!, on: :create
  before_validation :set_renewable_type!
  after_create { Inventory.create!(realm_location: self) }

  scope :flower_forests, -> { where(renewable_type: 'flower_forest') }
  scope :mines, -> { where(renewable_type: 'mine') }

  def self.max_items
    Event.full_moon.active? ? 7 : 6
  end

  def item_table
    raise "No items specified for renewable type #{renewable_type}" unless RENEWABLE_ITEMS[renewable_type]

    items = Item.where(name: RENEWABLE_ITEMS[renewable_type])
    raise "No items found for renewable type #{renewable_type}" if items.empty?

    items
  end

  def grow!
    return false if inventory_items.count >= Renewable.max_items

    item_id = select_item

    return false if item_id.nil?

    inventory_items.create!(item_id: item_id)

    inventory_items.joins(:item).pluck('items.name')
  end

  def full?
    inventory_items.count >= Renewable.max_items
  end

  def fill!
    grow! until full?
  end

  def self.next_growth_at
    now = Time.zone.now
    ahead10 = now + 10.minutes
    Time.new(ahead10.year, ahead10.month, ahead10.day, ahead10.hour, ahead10.min.floor(-1), 0, '+00:00')
  end

  def next_growth_at
    return false if full?

    self.class.next_growth_at + 10.seconds
  end

  private

  # Return id of the item that should be added to the inventory
  def select_item
    # Bias toward event item if Full Moon event is active
    if Event.full_moon.active? && (0..1).positive?
      return 61 # 'Nightshade Blossom'
    end

    # Bias toward stacking existing items, instead of adding more items
    if rand(0..3).positive?
      stackable_item_ids = item_table.pluck(:id) & inventory_items
                                                     .joins(:item)
                                                     .where(items: { stackable: true })
                                                     .pluck('items.id')

      if stackable_item_ids.count.positive?
        return stackable_item_ids.sample
      end
    end

    # Select a new item randomly if nothing applied above
    present_item_ids = inventory_items.pluck(:item_id).uniq
    possible_new_items = item_table.where.not(id: present_item_ids)
    if possible_new_items.count.positive?
      loot_generator = LootGenerator.new
      loot_generator.set_loot_table possible_new_items
      random_item = loot_generator.random_item(force: true)
      return random_item.id if random_item.present?
    end

    nil
  end

  def set_renewable_type!
    self.renewable_type = RENEWABLE_TYPES.sample

    self.name = {
      mine: 'Abandoned Mineshaft',
      flower_forest: 'Flower Forest',
    }[renewable_type.to_sym] || 'Resource'
  end
end
