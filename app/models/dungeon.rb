# frozen_string_literal: true

class Dungeon < RealmLocation
  ACTIVE_DURATION = 2.days # How long dungeons stay active
  DEFEATED_DURATION = 2.days # How long defeated dungeons appear on map
  EXPIRED_DURATION = 1.day # How long expired dungeons are kept in the database
  EXPIRATION_TIMER_LENGTH = 10.minutes # How much notice players get before dungeons are expired

  belongs_to :monster
  has_many :conquests, dependent: :delete_all
  has_many :users, through: :conquests
  has_many :spooks, dependent: :delete_all
  has_many :spooked_npcs, class_name: 'Npc', through: :spooks
  alias_attribute :defeated_by, :users

  enum status: { active: 'active', defeated: 'defeated', expired: 'expired' }

  validates :level, :status, presence: true
  validate :must_have_defeated_at

  before_validation :set_active_status, on: :create
  before_validation :set_real_world_location!, on: :create
  before_validation :set_region_and_coordinates!, on: :create
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

    query = RealWorldLocation.for_dungeon
    query = query.where(region: region) if region.present?
    count = query.count

    [10, count / 100].max
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

  private

  def must_have_defeated_at
    errors.add(:defeated_at, 'can\'t be blank') if defeated? && defeated_at.nil?
  end

  def remove_spooks!
    return if active?

    destroyed = spooks.destroy_all
    Rails.logger.debug { "❌ Removed #{destroyed.count} spooks" }
  end

  def set_active_status
    self.status = Dungeon.statuses[:active] if status.nil?
  end

  def set_real_world_location!
    return if real_world_location_id.present?

    occupied = Dungeon.select(:real_world_location_id)
    self.real_world_location = RealWorldLocation.available.for_dungeon.where.not(id: occupied).first
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

  def randomize_level_and_monster!
    if level.nil?

      # Lower level = Should have higher chance of spawning
      # Higher level = Should have lower chance of spawning
      # So we generate an array like [10, 9, 9, 9, 8, 8, 7, 7, 7, 7 ...] to be used for weighted randomization.
      diffs = []
      (1..9).each do |level|
        (3 * (10 - level)).floor.times do
          diffs << level
        end
      end

      # Level 10 dungeons are considered bosses, there can only be one active at any time.
      diffs << 10 if Dungeon.active.where(level: 10).count.zero?

      # Pick the difficulty level
      self.level = diffs.sample
    end

    self.monster = Monster.for_level(self.level)
    self.name = monster.name
  end
end
