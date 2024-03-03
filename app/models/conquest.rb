# frozen_string_literal: true

class Conquest < ApplicationRecord
  belongs_to :dungeon
  belongs_to :user
end
