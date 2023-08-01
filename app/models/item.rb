class Item < ApplicationRecord
  self.inheritance_column = nil
  validates :name, presence: true, uniqueness: true
  validates :type, presence: true
  validates :rarity, presence: true
  validate :classifications_valid
  validate :classification_bonuses_valid
  validate :lootable_from_any_monster

  scope :common, -> { where(rarity: Item.rarities[:common]) }
  scope :uncommon, -> { where(rarity: Item.rarities[:uncommon]) }
  scope :rare, -> { where(rarity: Item.rarities[:rare]) }
  scope :epic, -> { where(rarity: Item.rarities[:epic]) }
  scope :legendary, -> { where(rarity: Item.rarities[:legendary]) }

  enum type: [
    :amulet,
    :armor,
    :helmet,
    :ring,
    :shield,
    :weapon,
  ]
  enum rarity: {
    always: 1,
    common: 5,
    uncommon: 10,
    rare: 50,
    epic: 75,
    legendary: 100,
  }

  def lootable_from_any_monster
    if self.dropped_by_level.present? or self.dropped_by_classification.present?
      test = Monster.where('classification IN (?)', self.dropped_by_classification).find_by("level >= ?", self.dropped_by_level)
      if test.nil?
        errors.add(:base, "not lootable from any monster")
      end
    end
  end

  private
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
      errors.add(:base, "Has a classification bonus without any added attack or defense")
    end
  end
end
