class Location < ApplicationRecord
  belongs_to :real_world_location
  enum status: { active: 1, defeated: 2, cooldown: 0 }
  validates_associated :real_world_location
  validates_uniqueness_of :real_world_location_id
  validates :level, presence: true
  scope :npcs, -> { where(type: 'npc') }
  scope :dungeons, -> { where(type: 'dungeon') }

  after_initialize do |location|
    #puts "You have initialized an object!"
  end
  after_create do |location|
    puts "Spawned a new dungeon. There are now #{Location.count} dungeons."
  end
  after_destroy do |location|
    puts "De-spawned a dungeon. There are now #{Location.count} dungeons."
  end

  def self.generate_dungeon!
    location = Location.new
    location.real_world_location = RealWorldLocation
                                 .for_dungeon
                                 .where.not(id: [Location.pluck(:real_world_location_id)])
                                 .order("RANDOM()")
                                 .limit(1)
                                 .first

    diffs = []
    (1..10).each { |level|
      (10 - level).times do
        diffs << level
      end
    }
    location.level = diffs.sample

    location.save!
  end

  def type
    real_world_location.type
  end
end
