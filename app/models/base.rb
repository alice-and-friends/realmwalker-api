# frozen_string_literal: true

class Base < RealmLocation
  belongs_to :user
  before_validation :set_region_and_coordinates!, on: :create
  after_create { Inventory.create!(realm_location: self) }

  def name
    "#{user.name}'s base"
  end
end
