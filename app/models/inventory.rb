# frozen_string_literal: true

class Inventory < ApplicationRecord
  has_many :inventory_items, dependent: :delete_all
end
