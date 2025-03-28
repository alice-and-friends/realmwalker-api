# frozen_string_literal: true

module PlayerActionTypes
  TYPES = %w[
    flee
    attack
    use_item
    defend
    spell
    utility
  ].freeze

  def self.valid?(type)
    TYPES.include?(type.to_s)
  end
end
