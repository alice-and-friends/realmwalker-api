# frozen_string_literal: true

class Dungeon < RealmLocation
  ACTIVE_DURATION = 2.days # How long dungeons stay active
  DEFEATED_DURATION = 2.days # How long defeated dungeons appear on map
  EXPIRED_DURATION = 1.day # How long expired dungeons are kept in the database
  EXPIRATION_TIMER_LENGTH = 10.minutes # How much notice players get before dungeons are expired

  belongs_to :monster
  has_many :conquests, dependent: :destroy
  has_many :users, through: :conquests
  has_many :spooks, dependent: :destroy
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

  def spook_distance
    boss? ? 1100 : 225 # meters
  end

  def desc
    "level #{level} #{monster.classification}"
  end

  def difficulty_multiplier
    {
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
  end

  def loot_container_for(user)
    loot_generator = LootGenerator.new(user.loot_bonus)
    loot_generator.set_loot_table(monster.level, monster.classification)
    loot_generator.generate_loot
  end

  def battle_prediction_for(user)
    # Calculate baseline based on player level and dungeon level
    base_difficulty_score = (difficulty_multiplier * (user.level.to_f / 2)).floor.clamp(0, 100)

    # Descriptions of modifiers which will be displayed to end user
    modifier_descriptors_positive = []
    modifier_descriptors_negative = []

    # Player attack bonuses
    modifier_descriptors_positive << "+#{User::BASE_ATTACK} base attack"
    player_attack_bonus = user.attack_bonus(monster.classification)
    modifier_descriptors_positive << "+#{player_attack_bonus} from equipment" unless player_attack_bonus.zero?

    # Monster defense
    monster_defense = monster.defense
    modifier_descriptors_negative << "-#{monster_defense} from monster defense" unless monster_defense.zero?

    # Player attack penalties
    player_attack_penalty = 0
    if user.weapon.nil?
      player_attack_penalty = 10
      modifier_descriptors_negative << "-#{player_attack_penalty} attack penalty for equipping a weapon"
    end

    # Player defense
    player_defense_bonus = user.defense_bonus(monster.classification)

    # Calculate effective difficulty and possible overkill
    overkill = 0
    chance_of_success = (
      base_difficulty_score + User::BASE_ATTACK + player_attack_bonus - player_attack_penalty - monster_defense
    ).clamp(0, 100)

    # Calculate chance of bad stuff
    # modifier_descriptors_death = []
    chance_of_defeat = 100 - chance_of_success
    chance_of_escape = User::BASE_DEFENSE + player_defense_bonus
    risk_of_death_on_defeat = 100 - chance_of_escape
    # chance_of_inventory_loss = chance_of_death
    # chance_of_equipment_loss = chance_of_death / 10

    {
      base_chance: base_difficulty_score,
      chance_of_success: chance_of_success,
      overkill: overkill,
      modifiers_positive: modifier_descriptors_positive,
      modifiers_negative: modifier_descriptors_negative,
      # chance_of_defeat: chance_of_defeat,
      chance_of_escape: chance_of_escape,
      risk_of_death: {
        on_defeat: risk_of_death_on_defeat,
        overall: risk_of_death_on_defeat * chance_of_defeat / 100,
      }
      # chance_of_inventory_loss: chance_of_inventory_loss,
      # chance_of_equipment_loss: chance_of_equipment_loss,
      # modifiers_death: modifier_descriptors_death,
    }
  end

  def battle_as(user)
    Rails.logger.debug { "⚔️ #{user.name} started battle against #{monster.name}" }

    # Defaults
    monster_died = user_died = false
    inventory_changes = nil

    # Let's go
    prediction = battle_prediction_for(user)
    Rails.logger.debug {
 "⚔️ #{user.name} has #{prediction[:chance_of_success]}% chance of success, #{prediction[:chance_of_escape]}% chance of escape" }
    roll = rand(1..100)
    user_won = (roll <= prediction[:chance_of_success])
    Rails.logger.debug { "⚔️ #{user.name} rolled a #{roll} and #{user_won ? 'won' : 'lost'}" }
    if user_won
      defeated_by! user # Update dungeon as defeated

      xp_level_change = user.gains_or_loses_xp(monster.xp)

      monster_died = (rand(1..100) > monster.defense)
      if monster_died
        loot_container = loot_container_for(user)
        user.gains_loot(loot_container)
        inventory_changes = {
          loot: loot_container,
        }
      end
    else # user lost the battle
      user_died = (rand(1..100) <= prediction[:risk_of_death][:on_defeat])
      if user_died
        xp_level_change, inventory_changes = user.handle_death
      else
        xp_level_change = user.gains_or_loses_xp(0)
      end
    end

    {
      battle_result: {
        user_won: user_won,
        user_died: user_died,
        monster_died: monster_died,
      },
      inventory_changes: inventory_changes,
      xp_level_change: xp_level_change,
      xp_level_report: user.xp_level_report,
    }
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
