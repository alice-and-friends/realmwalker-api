# frozen_string_literal: true

class LootGenerator
  @reduced_mode = false
  LOOT_TIERS = {
    'always' => 1,        # 1 in 1
    'very_common' => 0.5, # 1 in 2
    'common' => 0.1666,   # 1 in 6
    'uncommon' => 0.05,   # 1 in 20
    'rare' => 0.03,       # 1 in 33
    'epic' => 0.02,       # 1 in 50
    'legendary' => 0.01,  # 1 in 100
  }.freeze
  GOLD_RANGES = {
    1 => 3..20,      # Range: 17   Average: 11.5
    2 => 5..40,      # Range: 35   Average: 22.5
    3 => 8..100,     # Range: 92   Average: 54
    4 => 21..180,    # Range: 159  Average: 100.5
    5 => 110..300,   # Range: 190  Average: 205
    6 => 160..550,   # Range: 390  Average: 355
    7 => 180..600,   # Range: 420  Average: 390
    8 => 250..700,   # Range: 450  Average: 475
    9 => 300..800,   # Range: 500  Average: 550
    10 => 600..1100, # Range: 500  Average: 850
  }.freeze

  def set_player(player)
    @player = player
  end

  def set_dungeon(dungeon)
    @dungeon = dungeon
    @monster_classification = @dungeon.monster.classification
    @gold_range = GOLD_RANGES[@dungeon.level]
    set_loot_table(@dungeon.monster.lootable_items)
  end

  def set_loot_table(loot_table)
    @loot_table = loot_table
    @loot_table_rarity_tiers = @loot_table.pluck(:rarity).uniq
  end

  def reduced_mode!
    @reduced_mode = true
  end

  # Returns a loot container, with a small chance of extra contents from a second generated container
  def generate_loot
    raise 'must set player before generating loot' unless @player.instance_of? User

    raise 'must set dungeon before generating loot' unless @dungeon.instance_of? Dungeon

    loot = generate_loot_single_set

    return loot if @reduced_mode

    # Apply the chance of an additional loot roll based on player loot bonus
    loot += generate_loot_single_set if rand <= @player.loot_bonus

    loot
  end

  # Returns a random item from a specific set of types, or nil
  def random_item(item_types: Item::ITEM_TYPES, force: false)
    tier = random_tier_for_item_types(item_types: item_types, force: force)
    if tier
      tier_table = @loot_table.where(rarity: tier, type: item_types)
      return tier_table.sample unless tier_table.empty?
    end
    nil
  end

  private

  # Generates a standard loot container
  def generate_loot_single_set
    loot_container = LootContainer.new

    loot_container.add_gold(random_gold_amount)
    loot_container.add_item(random_equipment_or_none)
    loot_container.add_item(random_valuable_or_none)
    loot_container.add_item(random_creature_product_or_none)

    # Dragon bonus: Dragons can drop twice as much gold and valuables
    if @monster_classification == 'dragon' && !@reduced_mode
      loot_container.add_gold(random_gold_amount)
      loot_container.add_item(random_valuable_or_none)
    end

    # Dungeon bonus: Add whatever is in the dungeon's inventory
    if @dungeon.inventory
      loot_container.merge(@dungeon.inventory.as_loot_container)
      @dungeon.inventory.destroy!
    end

    loot_container
  end

  # Returns a random tier to randomize loot from, for a specific set of item types, or nil
  def random_tier_for_item_types(item_types: Item::ITEM_TYPES, force: false)
    raise 'need one or more item types' if item_types.blank?

    tier = nil
    @loot_table_rarity_tiers.each do |loot_tier|
      probability = LOOT_TIERS[loot_tier]
      probability /= 10 if @reduced_mode # Reduced probability if just searching an area, as opposed to battling
      if rand < probability && @loot_table.exists?(rarity: loot_tier, type: item_types)
        tier = loot_tier
        break
      end
    end

    if force
      raise 'force random item failed because loot table is empty' if @loot_table.empty?

      # Use whatever the most common tier is
      return @loot_table_rarity_tiers.first if tier.nil?
    end

    tier
  end

  # Returns a random piece of equipment or nil
  def random_equipment_or_none
    random_item(item_types: Item::EQUIPMENT_TYPES) if @loot_table.exists?
  end

  # Returns a random valuable or nil
  def random_valuable_or_none
    random_item(item_types: ['valuable']) if @loot_table.exists?
  end

  # Returns a random creature product or nil
  def random_creature_product_or_none
    random_item(item_types: ['creature_product']) if @loot_table.exists?
  end

  # Returns a random amount of gold
  def random_gold_amount
    # Check if gold should be dropped based on a 90% chance (10% chance of no gold), or 75% in reduced mode (25% chance of no gold)
    chance_of_gold = @reduced_mode ? 0.9 : 0.75
    gold_amount = rand < chance_of_gold ? rand(@gold_range) : 0
    gold_amount /= 10 if @reduced_mode
    gold_amount
  end
end
