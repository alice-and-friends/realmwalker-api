# frozen_string_literal: true

class Spook < ApplicationRecord
  belongs_to :npc
  belongs_to :dungeon
end
