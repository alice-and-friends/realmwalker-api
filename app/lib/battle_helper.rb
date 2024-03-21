# frozen_string_literal: true

class BattleHelper
  BattleResult = Struct.new(:user_won, :user_died, :monster_died)

  def initialize(dungeon, user)
    throw('Not a dungeon') unless dungeon.instance_of?(Dungeon)
    throw('Not a user') unless user.instance_of?(User)
    @dungeon = dungeon
    @monster = dungeon.monster
    @user = user
  end

  # Battle difficulty multiplier to use for each dungeon level
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
    }[@dungeon.level]
  end

  def battle_prediction
    dungeon_difficulty_class = @dungeon.difficulty_class_for @user

    # Descriptions of modifiers which will be displayed to end user
    modifier_descriptors_positive = []
    modifier_descriptors_negative = []

    # Player attack bonuses
    modifier_descriptors_positive << "+#{User::BASE_ATTACK} base attack"
    player_attack_bonus = @user.attack_bonus(@monster.classification)
    modifier_descriptors_positive << "+#{player_attack_bonus} from equipment" unless player_attack_bonus.zero?

    # Monster defense
    monster_defense = @monster.defense
    modifier_descriptors_negative << "-#{monster_defense} from monster defense" unless monster_defense.zero?

    # Player attack penalties
    player_attack_penalty = 0
    if @user.weapon.nil?
      player_attack_penalty = 10
      modifier_descriptors_negative << "-#{player_attack_penalty} attack penalty for equipping a weapon"
    end

    # Player defense
    player_defense_bonus = @user.defense_bonus(@monster.classification)

    # Calculate effective difficulty and possible overkill
    overkill = 0
    chance_of_success = (
      dungeon_difficulty_class + User::BASE_ATTACK + player_attack_bonus - player_attack_penalty - monster_defense
    ).clamp(0, 100)

    # Calculate chance of bad stuff
    # modifier_descriptors_death = []
    chance_of_defeat = 100 - chance_of_success
    chance_of_escape = User::BASE_DEFENSE + player_defense_bonus
    risk_of_death_on_defeat = 100 - chance_of_escape
    # chance_of_inventory_loss = chance_of_death
    # chance_of_equipment_loss = chance_of_death / 10

    {
      base_chance: dungeon_difficulty_class,
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

  def generate_loot_container
    loot_generator = LootGenerator.new(@user.loot_bonus)
    loot_generator.set_loot_table(@monster)
    loot_generator.generate_loot
  end

  def battle
    monster = @dungeon.monster
    Rails.logger.debug { "⚔️ #{@user.name} started battle against #{monster.name}" }

    # Defaults
    monster_died = user_died = false
    inventory_changes = nil

    # Let's go
    prediction = battle_prediction
    Rails.logger.debug {
      "⚔️ #{@user.name} has #{prediction[:chance_of_success]}% chance of success, #{prediction[:chance_of_escape]}% chance of escape" }
    roll = rand(1..100)
    user_won = (roll <= prediction[:chance_of_success])
    Rails.logger.debug { "⚔️ #{@user.name} rolled a #{roll} and #{user_won ? 'won' : 'lost'}" }
    if user_won
      @dungeon.defeated_by! @user # Update dungeon as defeated

      xp_level_change = @user.gains_or_loses_xp(monster.xp)

      monster_died = (rand(1..100) > monster.defense)
      if monster_died
        loot_container = generate_loot_container
        @user.gains_loot(loot_container)
        inventory_changes = {
          loot: loot_container,
        }
      end
    else # user lost the battle
      user_died = (rand(1..100) <= prediction[:risk_of_death][:on_defeat])
      if user_died
        xp_level_change, inventory_changes = @user.handle_death
      else
        xp_level_change = @user.gains_or_loses_xp(0)
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
      xp_level_report: @user.xp_level_report,
    }
  end
end
