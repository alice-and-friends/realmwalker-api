# frozen_string_literal: true

class LootGenerator
  def initialize(player_loot_bonus = 0.0)
    @player_loot_bonus = player_loot_bonus
    @loot_tiers = {
      'legendary' => 0.01, # 1 in 100
      'epic' => 0.02, # 2 in 100
      'rare' => 0.03, # 3 in 100
      'uncommon' => 0.05, # 1 in 20
      'common' => 0.1666, # 1 in 6
    }
    @loot_table = Item.none # We will populate this based on monster level and classification
    @gold_ranges = {
      1 => 3..20,     # Range: 17   Average: 11.5
      2 => 5..40,     # Range: 35   Average: 22.5
      3 => 8..100,    # Range: 92   Average: 54
      4 => 21..180,   # Range: 159  Average: 100.5
      5 => 110..300,  # Range: 190  Average: 205
      6 => 160..550,  # Range: 390  Average: 355
      7 => 180..600,  # Range: 420  Average: 390
      8 => 250..700,  # Range: 450  Average: 475
      9 => 300..800,  # Range: 500  Average: 550
      10 => 600..1100 # Range: 500  Average: 850
    }
    @gold_range = nil # We will populate this based on monster level
  end

  def set_loot_table(monster_level, monster_classification)
    @loot_table = Item.where(
      ':classification = ANY(dropped_by_classification) AND :level >= dropped_by_level',
      classification: monster_classification,
      level: monster_level
    )
    @gold_range = @gold_ranges[monster_level]
  end

  def generate_loot
    loot = generate_loot_single_set

    # Apply the chance of an additional loot roll based on player loot bonus
    loot += generate_loot_single_set if rand <= @player_loot_bonus

    loot
  end

  private

  def generate_loot_single_set
    loot_container = LootContainer.new

    tier = nil
    @loot_tiers.each do |loot_tier, probability|
      if rand < probability
        tier = loot_tier
        break
      end
    end

    if tier && @loot_table.exists? && !@loot_table.empty?
      loot_container.add_item(@loot_table.sample)
    end

    # Check if gold should be dropped based on a 90% chance (10% chance of no gold)
    if rand >= 0.1
      loot_container.add_gold(rand(@gold_range))
    end

    loot_container
  end
end
