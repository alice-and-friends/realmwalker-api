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
  has_many :dungeon_searches, dependent: :delete_all
  has_many :searching_users, through: :dungeon_searches, source: :user
  alias_attribute :defeated_by, :users

  validates :level, :hp, presence: true
  validates :status, presence: true, inclusion: [
    statuses[:active],
    statuses[:defeated],
    statuses[:expired],
  ]
  validate :must_have_defeated_at

  before_validation :randomize_real_world_location!, on: :create
  before_validation :set_region_and_coordinates!, on: :create
  before_validation :set_timezone!, on: :create
  before_validation :randomize_level_and_monster!, on: :create
  after_create { Inventory.create!(realm_location: self) } # TODO: Consider performance implications. Not every Dungeon needs an inventory right away?

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
  # TODO: Consider raising the minimum slightly during night, to support undead spawn?
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
    level >= 90
  end

  # NPCs that are near an active dungeon may become "spooked"
  def spook_distance
    boss? ? 1100 : 225 # meters
  end

  def name
    attributes['name'] || monster.name
  end

  delegate :desc, to: :monster

  def search_defeated_dungeon(user)
    raise "Can't search active dungeon" if active?

    # Generally we don't expect users to search Expired dungeons, however this might happen on occasion,
    # if they interact with a dungeon at the same moment that it expires, so we allow for that.

    loot_generator = LootGenerator.new
    loot_generator.set_dungeon self
    loot_generator.set_player user
    loot_generator.reduced_mode! # Will generate less loot in this mode, because the looting is not related to winning a battle
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
      # Battle.create!(realm_location: self, monster: monster, user: user)
      self.status = Dungeon.statuses[:defeated]
      self.defeated_at = Time.current if defeated_at.nil? # defeated_at should always be the FIRST time a dungeon was defeated
      save!
      remove_spooks!
    end
  end

  def spook_nearby_shopkeepers!
    return unless active? # No one should be spooked by an inactive dungeon

    # Shopkeeper scope excludes castles etc
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
    raise 'Already scheduled' if expiry_job_id

    job_id = DungeonExpirationWorker.perform_in(Dungeon::EXPIRATION_TIMER_LENGTH, id)
    update!(expiry_job_id: job_id, expires_at: Dungeon::EXPIRATION_TIMER_LENGTH.from_now)
  end

  def cancel_expiration!
    return unless expiry_job_id

    Sidekiq::ScheduledSet.new.find_job(expiry_job_id)&.delete
    update!(expiry_job_id: nil, expires_at: nil)
  end

  def defeated!
    raise('Use defeated_by! instead')
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

  # Handle the search process for a given user
  def handle_search_by(user)
    raise StandardError, 'Dungeon is active' if active?
    raise StandardError, 'Dungeon already searched by user' if DungeonSearch.exists?(user: user, dungeon: self)

    loot_container = search_defeated_dungeon(user)
    loot_container.grant_to(user, "User #{user.id} searched battlefield #{id}") unless loot_container.empty?
    DungeonSearch.create!(user: user, dungeon: self)

    loot_container
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

  def randomize_real_world_location!
    return if real_world_location_id.present?

    self.real_world_location = RealWorldLocation.available.for_dungeon.first
  end

  def randomize_level_and_monster!
    commit = lambda do |monster|
      self.monster = monster
      self.level = monster.level
      self.name = monster.name
      self.hp = monster.hp
      self
    end

    if monster.present?
      return commit.call monster
    end

    # Event
    # NB: level parameter will be ignored if event block executes
    full_moon_event = Event.find_by(name: 'Full moon')
    if full_moon_event&.active? && rand(0..3).zero? # 1/4 chance to spawn a Werecreature
      werewolf = Monster.find_by(name: 'Werewolf')
      return commit.call werewolf
    end

    if level.present?
      monster_pool = Monster.pool_for_timezone(timezone).select { |o| o[:level] == level }
      raise "No monsters found for level #{level}" if monster_pool.empty?
    else
      monster_pool = Monster.weighted_pool_for_timezone(timezone)
      raise 'No monsters found' if monster_pool.empty?
    end

    commit.call Monster.find(monster_pool.sample[:id])
  end
end
