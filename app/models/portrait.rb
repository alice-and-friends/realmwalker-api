# frozen_string_literal: true

class Portrait < ApplicationRecord
  include Species
  include Gender

  validate :valid_species
  validate :valid_genders
  validate :valid_groups

  def valid_species
    errors.add(:species, :invalid) if species.empty? || species.any? { |i| !i.in? Species::SPECIES }
  end

  def valid_genders
    errors.add(:genders, :invalid) if genders.empty? || genders.any? { |i| !i.in? Gender::GENDERS }
  end

  def valid_groups
    errors.add(:groups, :invalid) if groups.empty? || groups.any? { |i| !i.in? Npc::SHOP_TYPES }
  end
end
