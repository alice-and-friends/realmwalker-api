# frozen_string_literal: true

class LootGenerator
  def initialize(player_loot_bonus = 0.0)
    @player_loot_bonus = player_loot_bonus
    @monster_classification = nil
    @loot_tiers = {
      'legendary' => 0.01, # 1 in 100
      'epic' => 0.02, # 2 in 100
      'rare' => 0.03, # 3 in 100
      'uncommon' => 0.05, # 1 in 20
      'common' => 0.1666, # 1 in 6
    }
    @loot_table = Item.none # We will populate this based on monster level and classification
    @gold_ranges = {
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
    }
    @gold_range = nil # We will populate this based on monster level
  end

  def set_loot_table(monster_level, monster_classification)
    @monster_classification = monster_classification
    @loot_table = Item.where(
      ':classification = ANY(dropped_by_classifications) AND :level >= dropped_by_level',
      classification: monster_classification,
      level: monster_level,
    )
    @gold_range = @gold_ranges[monster_level]
  end

  # Returns a loot container, with a small chance of extra contents from a second generated container
  def generate_loot
    loot = generate_loot_single_set

    # Apply the chance of an additional loot roll based on player loot bonus
    loot += generate_loot_single_set if rand <= @player_loot_bonus

    loot
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
    if @monster_classification == 'dragon'
      loot_container.add_gold(random_gold_amount)
      loot_container.add_item(random_valuable_or_none)
    end

    loot_container
  end

  # Returns a random tier to randomize loot from, for a specific set of item types, or nil
  def random_tier_for_item_types(item_types)
    Throw('need one or more item types') if item_types.blank?

    tier = nil
    @loot_tiers.each do |loot_tier, probability|
      if rand < probability && @loot_table.exists?(rarity: loot_tier, type: item_types)
        tier = loot_tier
        break
      end
    end
    tier
  end

  # Returns a random piece of equipment or nil
  def random_equipment_or_none
    random_item_from_types(Item::EQUIPMENT_TYPES) if @loot_table.exists?
  end

  # Returns a random valuable or nil
  def random_valuable_or_none
    random_item_from_types(['valuable']) if @loot_table.exists?
  end

  # Returns a random creature product or nil
  def random_creature_product_or_none
    random_item_from_types(['creature_product']) if @loot_table.exists?
  end

  # Returns a random item from a specific set of types, or nil
  def random_item_from_types(item_types)
    tier = random_tier_for_item_types(item_types)
    if tier
      tier_table = @loot_table.where(rarity: tier, type: item_types)
      return tier_table.sample unless tier_table.empty?
    end
    nil
  end

  # Returns a random amount of gold
  def random_gold_amount
    # Check if gold should be dropped based on a 90% chance (10% chance of no gold)
    rand >= 0.1 ? rand(@gold_range) : 0
  end
end
