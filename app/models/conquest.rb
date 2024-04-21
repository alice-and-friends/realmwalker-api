# frozen_string_literal: true

class Conquest < ApplicationRecord
  belongs_to :realm_location, optional: true
  belongs_to :monster, optional: true
  belongs_to :user

  validates :realm_location_type, presence: true
  validate :must_have_monster, if: :dungeon?

  before_validation :set_realm_location_type, on: :create
  before_validation :set_monster, on: :create, if: :dungeon?

  def description
    "#{user.name} defeated #{monster.name} at #{created_at}"
  end

  def dungeon?
    realm_location_type == 'dungeon'
  end

  private

  def set_realm_location_type
    self.realm_location_type = realm_location.type if realm_location.present?
  end

  def set_monster
    self.monster = realm_location.monster if realm_location.present?
  end

  def must_have_monster
    errors.add(:monster_id, 'can\'t be blank') if monster_id.nil?
  end
end
