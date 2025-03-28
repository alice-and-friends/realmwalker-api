# frozen_string_literal: true

module DamageTypes
  TYPES = %w[
    acid
    bludgeoning
    cold
    fire
    force
    lightning
    necrotic
    piercing
    poison
    psychic
    radiant
    slashing
    thunder
  ].freeze

  def self.valid?(type)
    TYPES.include?(type.to_s)
  end
end
