# frozen_string_literal: true

class Inventory < ApplicationRecord
  has_many :inventory_items, dependent: :delete_all
  belongs_to :user, optional: true
  belongs_to :realm_location, optional: true
  validates :user_id, :realm_location_id, uniqueness: true, allow_nil: true
  validate :must_belong_to_something
  validates :gold, numericality: { greater_than_or_equal_to: 0 }

  def owner
    realm_location.present? ? realm_location.user : user
  end

  private

  def must_belong_to_something
    errors.add('Inventory must belong to either a user or a realm location') if user_id.nil? && realm_location_id.nil?
  end
end
