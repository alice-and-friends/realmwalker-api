# frozen_string_literal: true

class DungeonSearch < ApplicationRecord
  belongs_to :user
  belongs_to :dungeon
  alias_attribute :dungeon_id, :realm_location_id

  validates :user_id, uniqueness: { scope: :realm_location_id, message: 'has already searched this dungeon' }
end

