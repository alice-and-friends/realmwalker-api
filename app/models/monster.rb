class Monster < ApplicationRecord
  CLASSIFICATIONS = %w[aberration beast celestial construct dragon elemental fey fiend giant humanoid monstrosity ooze plant undead]
  TAGS = %w[]

  validate :has_classification
  validate :tags_are_valid

  def self.for_level(level)
    m = Monster.where(level: level).sample
    throw("No monsters for level #{level}") if m.nil?
    m
  end

  def xp
    standard_rate = (10*l)**2 + (l*100)
    level_10_bonus = 4000
    return standard_rate + level_10_bonus if self.level == 10
    standard_rate
  end

  private
  def has_classification
    # Should have one or more primary type(s)
    unless classification.in? CLASSIFICATIONS
      errors.add(:classification, "has invalid classification #{classification}")
      puts self.inspect
    end
  end
  def tags_are_valid
    # Should have only valid types
    tags.each do |tag|
      unless tag.in? TAGS
        errors.add(:tags, "contains an invalid tag '#{tags}'")
      end
    end
  end
end
