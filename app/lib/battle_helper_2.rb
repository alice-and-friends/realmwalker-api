# frozen_string_literal: true

class BattleHelper2
  BattleResult = Struct.new(:user_won, :user_died, :monster_died)

  def initialize(dungeon, user)
    throw('Not a dungeon') unless dungeon.instance_of?(Dungeon)
    throw('Not a user') unless user.instance_of?(User)
    @dungeon = dungeon
    @monster = dungeon.monster
    @user = user
  end

  def player_damage_formula
    # Basic
    base = (@user.level / 2.0).ceil
    variance_max = (@user.level / 2.0).ceil
    variance = rand(-variance_max..variance_max)

    # Bonuses
    equipment_attack_base = @user.equipped_items.sum('items.attack_bonus')
    equipment_attack_classification_bonus = @user.equipped_items.where(
      'items.classification_attack_bonus': @dungeon.monster.classification,
    ).sum('items.attack_bonus')
    equipment_attack_total = equipment_attack_base + equipment_attack_classification_bonus
    no_weapon_penalty = 0
    weapon_ability_score = AbilityScores::ABILITY_SCORE_BASE
    weapon_ability = nil
    if @user.weapon.present?
      weapon_ability = @user.weapon.item.weapon_ability
      weapon_ability_score = @user.ability_score(weapon_ability)
    else
      no_weapon_penalty = -5
    end
    bonus_damage = [0, ((weapon_ability_score / 10.0) * (equipment_attack_total * 2)).floor].max

    # Result
    predicted_damage = [1, base + bonus_damage + no_weapon_penalty].max
    random_damage = [1, (base + bonus_damage + no_weapon_penalty + variance).floor].max
    min_damage = [1, (base + bonus_damage + no_weapon_penalty - variance_max).floor].max
    max_damage = [1, (base + bonus_damage + no_weapon_penalty + variance_max).floor].max

    {
      base_damage: base,
      equipment_attack_base: equipment_attack_base,
      equipment_attack_classification_bonus: equipment_attack_classification_bonus,
      equipment_attack_total: equipment_attack_total,
      no_weapon_penalty: no_weapon_penalty,
      weapon_ability: weapon_ability,
      weapon_ability_score: weapon_ability_score,
      bonus_damage: bonus_damage,
      variance: variance_max,
      predicted_damage: predicted_damage,
      random_damage: random_damage,
      min_damage: min_damage,
      max_damage: max_damage,
    }
  end
end
