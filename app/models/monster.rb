# frozen_string_literal: true

class Monster < ApplicationRecord
  validate :has_classification
  validate :tags_are_valid

  CLASSIFICATIONS = %w[aberration beast celestial construct dragon elemental fey fiend giant humanoid monstrosity ooze plant undead].freeze
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
  TAGS = %w[].freeze


  def self.for_level(level)
    m = Monster.where(level: level).sample
    throw("No monsters for level #{level}") if m.nil?
    m
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

  def has_classification
    # Should have one or more primary type(s)
    unless classification.in? CLASSIFICATIONS
      errors.add(:classification, "has invalid classification #{classification}")
    end
  end

  def tags_are_valid
    # Should have only valid types
    tags.each do |tag|
      errors.add(:tags, "contains an invalid tag '#{tags}'") unless tag.in? TAGS
    end
  end
end
