# frozen_string_literal: true

class Monster < ApplicationRecord
  CACHE_PREFIX = 'monster.pool'
  # TAGS = %w[].freeze

  has_many :battles, dependent: :delete_all
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
  after_commit -> { Rails.cache.delete_matched CACHE_PREFIX }

  scope :day_only, -> { where(spawn_time: 'day') }
  scope :night_only, -> { where(spawn_time: 'night') }
  scope :day_time,   -> { where(spawn_time: ['day', nil]) }
  scope :night_time, -> { where(spawn_time: ['night', nil]) }
  scope :any_time,   -> { where(spawn_time: nil) }

  def self.pool_for_timezone(timezone)
    raise "#{timezone.inspect} is not a recognized timezone" unless timezone.in? Timezone.names

    DateTimeHelper.day_time_in_zone?(timezone) ? pool(:day_time) : pool(:night_time)
  end

  def self.weighted_pool_for_timezone(timezone)
    raise "#{timezone.inspect} is not a recognized timezone" unless timezone.in? Timezone.names

    DateTimeHelper.day_time_in_zone?(timezone) ? weighted_pool(:day_time) : weighted_pool(:night_time)
  end

  def self.pool(scope_symbol)
    cache_name = "#{CACHE_PREFIX}_#{scope_symbol}"
    Rails.cache.fetch(cache_name, expires_in: 3.hours) do
      send(scope_symbol).where(auto_spawn: true).pluck(:id, :level).map do |id, level|
        { id: id, level: level }
      end
    end
  rescue NoMethodError
    raise 'Not a valid Monster scope, try one of [:all, :day_time, :night_time, :any_time]'
  end

  def self.weighted_pool(scope_symbol)
    cache_name = "#{CACHE_PREFIX}_weighted_#{scope_symbol}"
    Rails.cache.fetch(cache_name, expires_in: 3.hours) do
      send(scope_symbol).where(auto_spawn: true).pluck(:id, :level).flat_map do |id, level|
        Array.new(((100 - level) / 2) + 1, { id: id, level: level })
      end
    end
  rescue NoMethodError
    raise 'Not a valid Monster scope, try one of [:all, :day_time, :night_time, :any_time]'
  end

  def desc
    "level #{level} #{classification}"
  end

  def hp
    (
      (level * 1.5)**1.367
    ).floor + 7
  end

  def defense
    (
      (level + 1) / 5
    ).floor
  end

  def xp
    standard_rate = ((10 * level)**2) + (level * 100)
    level_10_bonus = 4000
    return standard_rate + level_10_bonus if level == 10

    standard_rate
  end

  private

  def must_be_valid_spawn_time
    return if spawn_time.nil? || Monster.spawn_times.value?(spawn_time)

    errors.add(:spawn_time, 'is not a valid spawn time')
  end

  # def tags_are_valid
  #   # Should have only valid types
  #   tags.each do |tag|
  #     errors.add(:tags, "contains an invalid tag '#{tags}'") unless tag.in? TAGS
  #   end
  # end
end
