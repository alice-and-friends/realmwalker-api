class Item < ApplicationRecord
  self.inheritance_column = nil

  enum item_types: { amulet: 0, armor: 1, helmet: 2, ring: 3, shield: 4, weapon: 5 }
  enum rarity_tiers: { always: 1, common: 5, uncommon: 10, rare: 50, epic: 75, legendary: 100, }

  validates :name, presence: true, uniqueness: true
  validates :type, inclusion: { in: item_types.keys }
  validates :rarity, inclusion: { in: rarity_tiers.keys }
  validate :classifications_valid
  validate :classification_bonuses_valid
  validate :lootable_from_any_monster

  scope :common, -> { where(rarity: Item.rarity_tiers[:common]) }
  scope :uncommon, -> { where(rarity: Item.rarity_tiers[:uncommon]) }
  scope :rare, -> { where(rarity: Item.rarity_tiers[:rare]) }
  scope :epic, -> { where(rarity: Item.rarity_tiers[:epic]) }
  scope :legendary, -> { where(rarity: Item.rarity_tiers[:legendary]) }

  def bonuses
    bonuses = []
    bonuses << "+#{attack_bonus} attack" unless attack_bonus.zero?
    bonuses << "+#{defense_bonus} defense" unless defense_bonus.zero?
    bonuses << "+#{classification_attack_bonus} attack against #{classification_bonus}s" unless classification_attack_bonus.zero?
    bonuses << "+#{classification_defense_bonus} defense against #{classification_bonus}s" unless classification_defense_bonus.zero?
    bonuses << "+#{100*xp_bonus.to_i}% xp" unless xp_bonus.zero?
    bonuses << "+#{100*loot_bonus.to_i}% loot" unless loot_bonus.zero?
    bonuses
  end

  private

  def lootable_from_any_monster
    if dropped_by_level.present? or dropped_by_classification.present?
      test = Monster.where('classification IN (?)', dropped_by_classification).find_by('level >= ?', dropped_by_level)
      if test.nil?
        errors.add(:base, 'not lootable from any monster')
      end
    end
  end

  def classifications_valid
    if classification_bonus.present?
      errors.add(:classification_bonus, "#{classification_bonus} is not a valid classification") unless classification_bonus.in? Monster.classifications
    end
    if dropped_by_classification.present?
      dropped_by_classification.each do |c|
        errors.add(:dropped_by_classification, "#{c} is not a valid classification") unless c.in? Monster.classifications
      end
    end
  end

  def classification_bonuses_valid
    if classification_bonus.present? and (classification_attack_bonus+classification_defense_bonus).zero?
      errors.add(:base, 'Has a classification bonus without any added attack or defense')
    end
  end
end
