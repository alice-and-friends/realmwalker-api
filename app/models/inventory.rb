# frozen_string_literal: true

class Inventory < ApplicationRecord
  has_many :inventory_items, dependent: :delete_all
  belongs_to :user, optional: true
  belongs_to :base, optional: true
  validates :user_id, :base_id, uniqueness: true, allow_nil: true
  validate :belongs_to_something
  validates :gold, numericality: { greater_than_or_equal_to: 0 }

  def owner
    base.present? ? base.user : user
  end

  private

  def belongs_to_something
    errors.add('Inventory must belong to either a user or a user owned structure') if user_id.nil? && base_id.nil?
  end
end
