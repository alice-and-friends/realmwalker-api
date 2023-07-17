class Dungeon < RealmLocation
  has_one :battlefield
  belongs_to :defeated_by, class_name: 'User', optional: true

  validates :level, presence: true
  enum status: { active: 1, defeated: 2, expired: 0 }

  before_validation :set_real_world_location, :on => :create
  before_validation :randomize_level!, :on => :create

  def name
    'Hello world'
  end

  after_create do |location|
    puts "📌 Spawned a new dungeon. There are now #{Dungeon.count} dungeons, #{Dungeon.active.count} active."
  end
  after_destroy do |location|
    puts "❌ Destroyed a dungeon. There are now #{Dungeon.count} dungeons, #{Dungeon.active.count} active."
  end

  def battle_as(user)
    defeated_by! user
  end

  def defeated_by!(user)
    self.defeated_at = Time.now
    self.defeated_by = user
    self.save!
    Battlefield.create({
                         real_world_location: self.real_world_location,
                         dungeon: self
                       })
    self.defeated! if self.active?
    self.defeated?
  end

  private
  def set_real_world_location
    self.real_world_location = RealWorldLocation
                           .for_dungeon
                           .where.not(id: [Dungeon.pluck(:real_world_location_id)])
                           .order("RANDOM()")
                           .limit(1)
                           .first
  end
  def randomize_level!
    diffs = []
    (1..10).each { |level|
      (10 - level).times do
        diffs << level
      end
    }
    self.level = diffs.sample
  end
end
