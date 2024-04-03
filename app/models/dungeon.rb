# frozen_string_literal: true

class Dungeon < RealmLocation
  include LocationStatus

  ACTIVE_DURATION = 2.days # How long dungeons stay active
  DEFEATED_DURATION = 2.days # How long defeated dungeons appear on map
  EXPIRED_DURATION = 1.day # How long expired dungeons are kept in the database
  EXPIRATION_TIMER_LENGTH = 10.minutes # How much notice players get before dungeons are expired

  belongs_to :monster
  has_many :spooks, dependent: :delete_all
  has_many :spooked_npcs, class_name: 'Npc', through: :spooks
  alias_attribute :defeated_by, :users

  validates :level, presence: true
  validates :status, presence: true, inclusion: [
    statuses[:active],
    statuses[:defeated],
    statuses[:expired],
  ]
  validate :must_have_defeated_at

  before_validation :set_real_world_location!, on: :create
  before_validation :set_region_and_coordinates!, on: :create
  before_validation :set_timezone!, on: :create
  before_validation :randomize_level_and_monster!, on: :create

  after_create do |d|
    Rails.logger.debug {
      "📌 Spawned a new dungeon ##{d.id}, level #{d.level}, #{d.status}. There are now #{Dungeon.count} dungeons, #{Dungeon.active.count} active."
    }

    expire_nearby_dungeons! if boss?
    spook_nearby_shopkeepers!
  end
  after_destroy do |d|
    Rails.logger.debug "❌ Destroyed a dungeon. There are now #{Dungeon.count} dungeons, #{Dungeon.active.count} active."
  end

  # This function sets targets for how many active dungeons there should be (in each region)
  def self.min_active_dungeons(region = '')
    return 10 if Rails.env.test?

    # Calculate preferred lowest number of dungeons
    query = RealWorldLocation.for_dungeon
    query = query.where(region: region) if region.present?
    count = query.count
    target = count / 100

    # Event modifiers
    target *= 1.2 if Event.full_moon.active?

    [10, target.round].max
  end

  def boss?
    level == 10
  end

  # NPCs that are near an active dungeon may become "spooked"
  def spook_distance
    boss? ? 1100 : 225 # meters
  end

  delegate :desc, to: :monster

  def loot_container_for(user)
    loot_generator = LootGenerator.new(user.loot_bonus)
    loot_generator.set_loot_table(monster)
    loot_generator.generate_loot
  end

  def battle_prediction_for(user)
    helper = BattleHelper.new(self, user)
    helper.battle_prediction
  end

  def battle_as(user)
    helper = BattleHelper.new(self, user)
    helper.battle
  end

  def defeated_by!(user)
    Dungeon.transaction do
      cancel_expiration!
      defeated_by << user
      self.status = Dungeon.statuses[:defeated]
      self.defeated_at = Time.current if defeated_at.nil? # defeated_at should always be the FIRST time a dungeon was defeated
      save!
      remove_spooks!
    end
  end

  def spook_nearby_shopkeepers!
    return unless active? # No one should be spooked by an inactive dungeon

    nearby_shopkeepers = Npc.shopkeepers.joins(:real_world_location).where(
      'ST_DWithin(real_world_locations.coordinates::geography, :coordinates, :distance)',
      coordinates: coordinates,
      distance: spook_distance,
    )

    nearby_shopkeepers.each do |npc|
      npc.dungeons << self
    end

    Rails.logger.debug { "😱 Spooked #{nearby_shopkeepers.size} shopkeepers" }
  end

  def schedule_expiration!
    throw 'Already scheduled' if expiry_job_id

    job_id = DungeonExpirationWorker.perform_in(Dungeon::EXPIRATION_TIMER_LENGTH, id)
    update!(expiry_job_id: job_id, expires_at: Dungeon::EXPIRATION_TIMER_LENGTH.from_now)
  end

  def cancel_expiration!
    return unless expiry_job_id

    Sidekiq::ScheduledSet.new.find_job(expiry_job_id)&.delete
    update!(expiry_job_id: nil, expires_at: nil)
  end

  def defeated!
    throw('Use defeated_by! instead')
  end

  def expired!
    update!(status: Dungeon.statuses[:expired])
    remove_spooks!
  end

  # Calculate baseline battle difficulty based on player level and dungeon level.
  # This is a number between 0 and 100 which indicates the users chance % of winning the fight.
  # For example, a difficulty class of 14 means the player has 14% chance of success.
  def difficulty_class_for(user)
    base = {
      1 => 180.0,
      2 => 22.2,
      3 => 6.0,
      4 => 3.0,
      5 => 2.0,
      6 => 1.8,
      7 => 1.6,
      8 => 1.4,
      9 => 1.2,
      10 => 1.0,
    }[level]

    (base * (user.level.to_f / 2)).floor.clamp(0, 100)
  end

  private

  def must_have_defeated_at
    errors.add(:defeated_at, 'can\'t be blank') if defeated? && defeated_at.nil?
  end

  def remove_spooks!
    return if active?

    destroyed = spooks.destroy_all
    Rails.logger.debug { "❌ Removed #{destroyed.count} spooks" }
  end

  def set_real_world_location!
    return if real_world_location_id.present?

    occupied = Dungeon.select(:real_world_location_id)
    self.real_world_location = RealWorldLocation.available.for_dungeon.where.not(id: occupied).first
  end

  def set_timezone!
    self.timezone = real_world_location.timezone unless Rails.env.test?
  end

  def expire_nearby_dungeons!
    Dungeon.joins(:real_world_location)
           .where(
             'ST_DWithin(real_world_locations.coordinates::geography, :coordinates, :radius)',
             coordinates: coordinates,
             radius: 500,
           )
           .where.not(id: id)
           .find_each(&:expired!)
  end

  def randomize_level_and_monster!(allow_boss = false)
    random_level = lambda do
      # Lower level = Should have higher chance of spawning
      # Higher level = Should have lower chance of spawning
      # So we generate an array like [10, 9, 9, 8, 8, 8, 7, 7, 7, 7 ...] to be used for weighted randomization.
      levels = []
      (1..9).each do |level|
        multiplier = 1.30
        exponent = 1.70
        (multiplier * (10 - level)**exponent + 1).floor.times do
          levels << level
        end
      end

      # Level 10 dungeons are considered bosses, there can only be one active at any time.
      levels << 10 if allow_boss && Dungeon.active.where(level: 10).count.zero?
      levels.sample
    end

    random_monster = lambda do
      monsters_list = Monster.where(auto_spawn: true, level: level)
      begin
        if real_world_location.day?
          monsters_list = monsters_list.day_time
        elsif real_world_location.night?
          monsters_list = monsters_list.night_time

          # Increase rate of undead at night
          if rand(0..1)
            undead_list = monsters_list.where(classification: Monster.classifications[:undead])
            monsters_list = undead_list unless undead_list.empty?
          end
        end
      rescue RuntimeError
        monsters_list = monsters_list.any_time
      end
      raise "monster_list is empty! level:#{level}" if monsters_list.empty?

      monsters_list.sample
    end

    if level.nil? && monster.nil?
      # Event
      full_moon_event = Event.find_by(name: 'Full moon')&.active?
      if full_moon_event && rand(0..3).zero?
        werewolf = Monster.find_by(name: 'Werewolf')
        self.level = werewolf.level
        self.monster = werewolf
      end
    end

    self.level = random_level.call if level.nil?
    self.monster = random_monster.call if monster.nil?
    self.name = monster.name
  end
end
