# frozen_string_literal: true

class Monster < ApplicationRecord
  # TAGS = %w[].freeze

  has_many :monster_items, dependent: :delete_all
  has_many :lootable_items, through: :monster_items, source: :item

  enum classification: {
    aberration: 'aberration',
    beast: 'beast',
    celestial: 'celestial',
    construct: 'construct',
    dragon: 'dragon',
    elemental: 'elemental',
    fey: 'fey',
    fiend: 'fiend',
    giant: 'giant',
    humanoid: 'humanoid',
    monstrosity: 'monstrosity',
    ooze: 'ooze',
    plant: 'plant',
    undead: 'undead',
  }

  validates :name, presence: true, uniqueness: true
  validates :classification, presence: true
  # validate :tags_are_valid

  def self.for_level(level)
    monster = Monster.where(level: level).sample
    throw("No monsters for level #{level}") if monster.nil?
    monster
  end

  def desc
    "level #{level} #{classification}"
  end

  def defense
    (2 * level) - 2
  end

  def xp
    standard_rate = ((10 * level)**2) + (level * 100)
    level_10_bonus = 4000
    return standard_rate + level_10_bonus if level == 10

    standard_rate
  end

  private

  # def tags_are_valid
  #   # Should have only valid types
  #   tags.each do |tag|
  #     errors.add(:tags, "contains an invalid tag '#{tags}'") unless tag.in? TAGS
  #   end
  # end
end
