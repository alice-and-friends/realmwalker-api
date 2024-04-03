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
  enum spawn_time: {
    day: 'day',
    night: 'night',
  }

  validates :name, presence: true, uniqueness: true
  validates :classification, presence: true
  validate :must_be_valid_spawn_time
  # validate :tags_are_valid

  scope :day_time, lambda {
    spawn_time = arel_table[:spawn_time]
    where(spawn_time.eq('day').or(spawn_time.eq(nil)))
  }
  scope :night_time, lambda {
    spawn_time = arel_table[:spawn_time]
    where(spawn_time.eq('night').or(spawn_time.eq(nil)))
  }
  scope :any_time, lambda {
    spawn_time = arel_table[:spawn_time]
    where(spawn_time.eq(nil))
  }

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

  def must_be_valid_spawn_time
    return if spawn_time.nil? || Monster.spawn_times.values.include?(spawn_time)

    errors.add(:spawn_time, 'is not a valid spawn time')
  end

  # def tags_are_valid
  #   # Should have only valid types
  #   tags.each do |tag|
  #     errors.add(:tags, "contains an invalid tag '#{tags}'") unless tag.in? TAGS
  #   end
  # end
end
