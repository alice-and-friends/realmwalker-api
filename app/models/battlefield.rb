class Battlefield < RealmLocation
  belongs_to :dungeon
  validates_associated :dungeon
  validates_uniqueness_of :dungeon_id

  enum status: { active: 1, expired: 0 }
  #store :properties, accessors: [ :level, :defeated_at, :defeated_by ], coder: JSON

  def name
    'Hello world'
  end
end
