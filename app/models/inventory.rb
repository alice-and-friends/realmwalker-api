# frozen_string_literal: true

class Inventory < ApplicationRecord
  has_many :inventory_items, dependent: :delete_all
  belongs_to :user
  validates :user_id, uniqueness: true, allow_nil: true
end
