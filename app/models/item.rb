# frozen_string_literal: true

class Item < ApplicationRecord
  self.inheritance_column = nil
  EQUIPMENT_TYPES = %w[amulet armor helmet ring shield weapon].freeze
  ITEM_TYPES = %w[valuable creature_product plants_and_herbs miscellaneous] + EQUIPMENT_TYPES.freeze
  RARITIES = %w[always common uncommon rare epic legendary].freeze

  has_many :trade_offers, dependent: :delete_all
  has_many :inventory_items, dependent: :delete_all
  has_many :monster_items, dependent: :delete_all
  has_many :monsters, through: :monster_items, source: :monster
  alias_attribute :dropped_by, :monsters
  alias_attribute :lootable_from, :monsters

  validates :type, presence: true, inclusion: { in: ITEM_TYPES }
  validates :rarity, presence: true, inclusion: { in: RARITIES }, if: :lootable? || :equipment?
  validate :must_be_weapon_if_two_handed
  validates :name, presence: true, uniqueness: true
  validate :must_be_meaningful_bonus
  validate :must_have_stats_for_equipment
  validate :must_have_appropriate_rarity

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

  def lootable?
    dropped_by.any?
  end

  def value
    highest_buy_offer = trade_offers.order(buy_offer: :desc).select(:buy_offer).pluck(:buy_offer).first
    lowest_sell_offer = trade_offers.order(sell_offer: :asc).select(:sell_offer).pluck(:sell_offer).first

    return lowest_sell_offer if lowest_sell_offer && equipable?

    return highest_buy_offer if highest_buy_offer

    lowest_sell_offer
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
    bonuses << "+#{classification_attack_bonus} attack against #{classification_bonus.pluralize}" if classification_attack_bonus&.positive?
    bonuses << "+#{classification_defense_bonus} defense against #{classification_bonus.pluralize}" if classification_defense_bonus&.positive?
    bonuses << "+#{(100 * xp_bonus).to_i}% xp" if xp_bonus&.positive?
    bonuses << "+#{(100 * loot_bonus).to_i}% loot" if loot_bonus&.positive?
    bonuses
  end

  private

  def must_be_weapon_if_two_handed
    errors.add(:two_handed, 'Only weapons can be two handed') if two_handed && !weapon?
  end

  def must_be_meaningful_bonus
    if classification_bonus.present? && (classification_attack_bonus + classification_defense_bonus).zero?
      errors.add(:base, 'Has a classification bonus without any added attack or defense')
    end
  end

  def must_have_stats_for_equipment
    return unless equipable?

    # TODO
  end

  def must_have_appropriate_rarity
    return if equipable? # All rarities allowed for equipment

    if type == 'valuable'
      errors.add(:rarity, "#{name}: Rarity level '#{rarity}' not suitable for #{type}.") if rarity.in? %w[epic legendary]
      return
    end

    if rarity.in? %w[rare epic legendary]
      errors.add(:rarity, "#{name}: Rarity level '#{rarity}' is only suitable for equipment.")
    end
  end
end
