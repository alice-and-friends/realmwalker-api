# frozen_string_literal: true

class Item < ApplicationRecord
  self.inheritance_column = nil

  has_many :trade_offers, dependent: :destroy

  ITEM_TYPES = %w[amulet armor helmet ring shield weapon valuable creature_product].freeze
  EQUIPMENT_TYPES = %w[amulet armor helmet ring shield weapon].freeze
  RARITIES = %w[always common uncommon rare epic legendary].freeze
  validates :type, presence: true, inclusion: { in: ITEM_TYPES }
  validates :rarity, presence: true, inclusion: { in: RARITIES }
  validate :weapons_can_be_two_handed
  validates :name, presence: true, uniqueness: true
  validate :classifications_valid
  validate :classification_bonuses_valid
  validate :lootable_from_any_monster

  scope :common, -> { where(rarity: 'common') }
  scope :uncommon, -> { where(rarity: 'uncommon') }
  scope :rare, -> { where(rarity: 'rare') }
  scope :epic, -> { where(rarity: 'epic') }
  scope :legendary, -> { where(rarity: 'legendary') }

  def sold_by_npc?(npc)
    id.in? npc.sell_offers.pluck(:item_id)
  end

  def bought_by_npc?(npc)
    id.in? npc.buy_offers.pluck(:item_id)
  end

  def equipable?
    type.in? EQUIPMENT_TYPES
  end

  def weapon?
    type == 'weapon'
  end

  def bonuses
    bonuses = []
    bonuses << "+#{attack_bonus} attack" if attack_bonus&.positive?
    bonuses << "+#{defense_bonus} defense" if defense_bonus&.positive?
    bonuses << "+#{classification_attack_bonus} attack against #{classification_bonus}s" if classification_attack_bonus&.positive?
    bonuses << "+#{classification_defense_bonus} defense against #{classification_bonus}s" if classification_defense_bonus&.positive?
    bonuses << "+#{(100 * xp_bonus).to_i}% xp" if xp_bonus&.positive?
    bonuses << "+#{(100 * loot_bonus).to_i}% loot" if loot_bonus&.positive?
    bonuses
  end

  private

  def weapons_can_be_two_handed
    errors.add(:two_handed, 'Only weapons can be two handed') if two_handed && !weapon?
  end

  def lootable_from_any_monster
    if dropped_by_level.present? || dropped_by_classification.present?
      test = Monster.where('classification IN (?)', dropped_by_classification).find_by('level >= ?', dropped_by_level)
      if test.nil?
        errors.add(:base, "Item '#{name}' not lootable from any monster")
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
    if classification_bonus.present? && (classification_attack_bonus+classification_defense_bonus).zero?
      errors.add(:base, 'Has a classification bonus without any added attack or defense')
    end
  end
end
