class Battlefield < RealmLocation
  validates :level, presence: true
  enum status: { active: 1, expired: 0 }
  #store :properties, accessors: [ :level, :defeated_at, :defeated_by ], coder: JSON

  def name
    'Hello world'
  end
end
