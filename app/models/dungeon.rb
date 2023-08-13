# frozen_string_literal: true

class Dungeon < RealmLocation
  has_one :battlefield, dependent: :nullify # TODO: Should we just preserve the Dungeon for as long as Battlefield exists?
  belongs_to :monster
  belongs_to :defeated_by, class_name: 'User', optional: true

  validates :level, presence: true
  enum status: { active: 1, defeated: 2, expired: 0 }

  before_validation :set_real_world_location, on: :create
  before_validation :randomize_level_and_monster!, on: :create

  def self.max_dungeons
    return 10 if Rails.env.test?

    RealWorldLocation.for_dungeon.count / 22
  end

  delegate :name, to: :monster

  after_create do |d|
    Rails.logger.debug "📌 Spawned a new dungeon, level #{d.level}, #{d.status}. There are now #{Dungeon.count} dungeons, #{Dungeon.active.count} active."
  end
  after_destroy do |d|
    Rails.logger.debug "❌ Destroyed a dungeon. There are now #{Dungeon.count} dungeons, #{Dungeon.active.count} active."
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

  def battle_prediction_for(user)
    # Calculate baseline based on player level and dungeon level
    base_difficulty_score = (difficulty_multiplier * (user.level.to_f / 2)).floor
    base_difficulty_score = 100 if base_difficulty_score > 100
    base_difficulty_score = 0 if base_difficulty_score < 1

    # Descriptions of modifiers which will be displayed to end user
    modifier_descriptors_positive = []
    modifier_descriptors_negative = []

    # Player attack bonuses
    modifier_descriptors_positive << "+#{User::BASE_ATTACK} base attack"
    player_attack_bonus = user.attack_bonus(monster.classification)
    modifier_descriptors_positive << "+#{player_attack_bonus} from equipment" unless player_attack_bonus.zero?

    # Player attack penalties
    player_attack_penalty = 0
    if user.weapon.present? == false
      player_attack_penalty += 10
      modifier_descriptors_negative << "-#{player_attack_penalty} penalty for not wearing a weapon"
    end

    # Player defense
    player_defense_bonus = user.defense_bonus(monster.classification)

    # Monster defense
    monster_defense = monster.defense
    modifier_descriptors_negative << "-#{monster_defense} from monster defense" unless monster_defense.zero?

    # Calculate effective difficulty and possible overkill
    overkill = 0
    chance_of_success = base_difficulty_score + User::BASE_ATTACK + player_attack_bonus - player_attack_penalty - monster_defense
    if chance_of_success > 100
      overkill = chance_of_success - 100
      chance_of_success = 100
    elsif chance_of_success < 1
      chance_of_success = 0
    end

    # Calculate chance of bad stuff
    modifier_descriptors_death = []
    chance_of_death = 100 - chance_of_success
    if user.amulet_of_life?
      chance_of_death = 0
      modifier_descriptors_death << 'Your Amulet of Life protects you from death. The amulet will be destroyed if you lose the battle.'
    end
    chance_of_inventory_loss = chance_of_death
    chance_of_equipment_loss = chance_of_death / 10
    if user.amulet_of_loss?
      chance_of_inventory_loss = 0
      chance_of_equipment_loss = 0
      modifier_descriptors_death << 'Your Amulet of Loss will protect you from losing any items. The amulet will be destroyed if you lose the battle'
    end

    {
      base_chance: base_difficulty_score,
      chance_of_success: chance_of_success,
      overkill: overkill,
      modifiers_positive: modifier_descriptors_positive,
      modifiers_negative: modifier_descriptors_negative,
      chance_of_death: chance_of_death,
      chance_of_inventory_loss: chance_of_inventory_loss,
      chance_of_equipment_loss: chance_of_equipment_loss,
      modifiers_death: modifier_descriptors_death,
    }
  end

  def battle_as(user)
    Rails.logger.debug { "⚔️ #{user.name} started battle against #{monster.name}" }
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
    defeated!
    self.defeated_at = Time.current
    self.defeated_by = user
    save!
    Battlefield.create({ real_world_location: real_world_location, dungeon: self })
  end

  private

  def set_real_world_location
    self.real_world_location = RealWorldLocation
                               .for_dungeon
                               .where.not(id: [Dungeon.pluck(:real_world_location_id)])
                               .order('RANDOM()')
                               .limit(1)
                               .first
  end

  def randomize_level_and_monster!
    if level.nil?

      # Lower level = Should have higher chance of spawning
      # Higher level = Should have lower chance of spawning
      # So we generate an array like [10, 9, 9, 8, 8, 8, 7, 7, 7, 7 ...] to be used for weighted randomization.
      diffs = []
      (1..9).each do |level|
        (2 * (10 - level)).floor.times do
          diffs << level
        end
      end

      # Level 10 dungeons are considered bosses, there can only be one active at any time.
      diffs << 10 if Dungeon.active.where(level: 10).count.zero?

      # Pick the difficulty level
      self.level = diffs.sample
    end

    self.monster = Monster.for_level(self.level)
  end
end
