# frozen_string_literal: true

class Conquest < ApplicationRecord
  belongs_to :realm_location
  belongs_to :user
end
