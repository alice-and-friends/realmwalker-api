# frozen_string_literal: true

class Portrait < ApplicationRecord
  include Species
  include Gender

  validate :must_be_valid_species
  validate :must_be_valid_genders
  validate :must_be_valid_groups

  def must_be_valid_species
    errors.add(:species, :invalid) if species.empty? || species.any? { |i| !i.in? Species::SPECIES }
  end

  def must_be_valid_genders
    errors.add(:genders, :invalid) if genders.empty? || genders.any? { |i| !i.in? Gender::GENDERS }
  end

  def must_be_valid_groups
    errors.add(:groups, :invalid) if groups.any? { |i| !i.in? Npc::SHOP_TYPES }
  end
end
