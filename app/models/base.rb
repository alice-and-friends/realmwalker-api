# frozen_string_literal: true

class Base < RealmLocation
  belongs_to :owner, class_name: 'User'
  belongs_to :real_world_location, dependent: :destroy

  before_validation :set_region_and_coordinates!, on: :create
  after_create { Inventory.create!(realm_location: self) }

  def name
    "#{owner.name}'s base"
  end
end
