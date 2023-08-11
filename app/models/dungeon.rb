class Dungeon < RealmLocation
  has_one :battlefield
  belongs_to :monster
  belongs_to :defeated_by, class_name: 'User', optional: true

  validates :level, presence: true
  enum status: { active: 1, defeated: 2, expired: 0 }

  before_validation :set_real_world_location, :on => :create
  before_validation :randomize_level_and_monster!, :on => :create

  def self.max_dungeons
    RealWorldLocation.for_dungeon.count / 22
  end

  def name
    self.monster.name
  end

  after_create do |d|
    puts "📌 Spawned a new dungeon, level #{d.level}, #{d.status}. There are now #{Dungeon.count} dungeons, #{Dungeon.active.count} active."
  end
  after_destroy do |d|
    puts "❌ Destroyed a dungeon. There are now #{Dungeon.count} dungeons, #{Dungeon.active.count} active."
  end

  def battle_as(user)
    defeated_by! user # Mark dungeon as defeated
    {
      battle_result: {
        user_won: true,
        user_died: false
      },
      inventory_result: {
        inventory_lost: false,
        equipment_lost: false,
        amulet_of_loss_consumed: false,
        amulet_of_loss_life: false,
      },
      xp_level_change: user.gains_or_loses_xp(monster.xp),
      xp_level_report: user.xp_level_report,
    }
  end

  def defeated_by!(user)
    self.defeated!
    self.defeated_at = Time.now
    self.defeated_by = user
    save!
    Battlefield.create({
                         real_world_location: self.real_world_location,
                         dungeon: self
                       })
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
  def randomize_level_and_monster!
    diffs = []

    # Lower level = Should have higher chance of spawning
    # Higher level = Should have lower chance of spawning
    # So we generate an array like [10, 9, 9, 8, 8, 8, 7, 7, 7, 7 ...] to be used for weighted randomization.
    (1..9).each { |level|
      (2*(10 - level)).floor.times do
        diffs << level
      end
    }

    # Level 10 dungeons are considered bosses, there can only be one active at any time.
    diffs << 10 if Dungeon.active.where(level: 10).count.zero?

    # Pick the difficulty level
    self.level = diffs.sample

    self.monster = Monster.for_level(self.level)
  end
end
