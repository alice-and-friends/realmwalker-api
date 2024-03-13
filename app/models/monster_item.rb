# frozen_string_literal: true

class MonsterItem < ApplicationRecord
  belongs_to :monster
  belongs_to :item
end
