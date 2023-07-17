class RealmLocation < ApplicationRecord
  self.abstract_class = true

  belongs_to :real_world_location
  validates_associated :real_world_location
  validates_uniqueness_of :real_world_location_id

  def coordinates
    real_world_location.coordinates
  end

  def location_type
    self.class.name
  end
end
