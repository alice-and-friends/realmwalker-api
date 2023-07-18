class Monster < ApplicationRecord
  def self.for_level(level)
    Monster.where(level: level).sample
  end
end
