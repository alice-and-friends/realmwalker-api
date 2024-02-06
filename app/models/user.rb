# frozen_string_literal: true

class User < ApplicationRecord
  has_one :inventory, dependent: :destroy
  has_one :base, class_name: 'RealmLocation', dependent: :destroy
  has_many :dungeons, inverse_of: :defeated_by, foreign_key: 'defeated_by_id', dependent: :nullify

  MAX_XP = 1_000_000
  BASE_ATTACK = 10
  BASE_DEFENSE = 10
  ACHIEVEMENTS = %w[].freeze

  serialize :auth0_user_data, Auth0UserData

  # Create inventory and grant starting equipment to new players
  after_create { self.inventory = Inventory.create!(user: self) }
  after_create :give_starting_equipment

  validates :auth0_user_id, presence: true, uniqueness: true
  validate :valid_auth0_user_data
  validate :achievements_are_valid
  validate :access_token_expires

  delegate :gold, to: :inventory
  delegate :inventory_items, to: :inventory
  delegate :email, to: :auth0_user_data

  def self.total_xp_needed_for_level(l)
    ((10 * (l - 1))**2) + ((l - 1) * 100)
  end

  def self.find_by_access_token(access_token)
    return nil if access_token.nil?

    user = User.find_by(access_token: access_token)
    return nil unless user

    user.access_token_expires_at > Time.current ? user : nil
  end

  def name
    auth0_user_data.given_name
  end

  def player_tag
    "#{name}##{id}"
  end

  def inventory_count_by_item_id(item_id)
    inventory_items.where(item_id: item_id).count
  end

  def equipped_items
    inventory_items.joins(:item).where(is_equipped: true)
  end

  def gain_item(item)
    inventory_items.create(item: item)
  end

  def lose_item(item)
    inventory_items.find_by(item: item).destroy
  end

  # Equips an item, or advises the player that some items will be unequipped if the requested item is equipped
  #
  # @param [InventoryItem] inventory_item The InventoryItem to equip
  # @param [Boolean] force If true, will not warn that other items will become unequipped to make room
  # @return [Boolean] Whether the item was equipped
  # @return [InventoryItem[]] Which items need to be unequipped, or if force=true which items were unequipped by this function
  def equip_item(inventory_item, force = false)
    max_items_of_type = inventory_item.item.type == 'ring' ? 2 : 1
    items_to_unequip = []

    # NB: You probably don't change the order of these checks
    equipped_items_of_this_type = equipped_items.where('items.type': inventory_item.item.type)
    if inventory_item.item.two_handed == true
      items_to_unequip += equipped_items.where("type IN (?)", ['weapon', 'shield'])
    elsif equipped_items_of_this_type.count >= max_items_of_type
      if max_items_of_type > 1
        items_to_unequip << equipped_items_of_this_type.first
      else
        items_to_unequip += equipped_items_of_this_type
      end
    elsif inventory_item.item.type == 'shield'
      items_to_unequip += equipped_items.where('items.two_handed': true)
    end

    if items_to_unequip.empty?
      inventory_item.update!(is_equipped: true)
      return true, []
    else
      if force
        items_to_unequip.each do |unequip_this|
          unequip_item(unequip_this)
        end
        inventory_item.update!(is_equipped: true)
        return true, items_to_unequip
      else
        return false, items_to_unequip
      end
    end
  end

  def unequip_item(inventory_item)
    inventory_item.update!(is_equipped: false)
  end

  def weapon
    equipped_items.find_by(items: { type: 'weapon' })
  end

  def amulet_of_loss
    equipped_items.find_by(items: { name: 'Amulet of Loss' })
  end

  def amulet_of_life
    equipped_items.find_by(items: { name: 'Amulet of Life' })
  end

  def equipped?(item_name)
    equipped_items.find_by(items: { name: item_name }).present?
  end

  def attack_bonus(classification = nil)
    modifier = equipped_items.sum('items.attack_bonus')
    if classification
      modifier += equipped_items.where(items: { classification_bonus: classification }).sum("items.classification_attack_bonus")
    end
    modifier
  end

  def defense_bonus(classification = nil)
    modifier = equipped_items.sum('items.defense_bonus')
    if classification
      modifier += equipped_items.where(items: { classification_bonus: classification }).sum('items.classification_defense_bonus')
    end
    modifier
  end

  def set_level
    # Check if current level is accurate
    current_level_xp_req = User.total_xp_needed_for_level(level)
    next_level_xp_req = User.total_xp_needed_for_level(level + 1)
    return if (xp >= current_level_xp_req) && (xp < next_level_xp_req)

    # Calculate new level
    n = 1
    n += 1 while User.total_xp_needed_for_level(n) <= xp
    self.level = n - 1
  end

  def xp_level_report
    next_level_at = User.total_xp_needed_for_level(level + 1)
    levels_xp_diff = User.total_xp_needed_for_level(level + 1) - User.total_xp_needed_for_level(level)
    level_xp_surplus = xp - User.total_xp_needed_for_level(level)
    {
      xp: xp,
      level: level,
      next_level_at: next_level_at,
      to_next_level: next_level_at - xp,
      next_level_progress: (level_xp_surplus.to_f / levels_xp_diff * 100.0).floor
    }
  end

  def xp_multiplier
    1.0 + equipped_items.sum('items.xp_bonus')
  end

  def loot_bonus
    equipped_items.sum('items.loot_bonus')
  end

  def gains_or_loses_gold(amount)
    prev_gold = inventory.gold.freeze

    inventory.gold += amount
    inventory.gold = 0 if inventory.gold.negative? # Can't have less than 0 gold
    inventory.save!
    {
      prev_gold: prev_gold,
      current_gold: inventory.gold,
      gold_diff: inventory.gold - prev_gold,
    }
  end

  def gains_or_loses_xp(amount)
    prev_xp = xp.freeze
    prev_level = level.freeze

    (amount *= xp_multiplier).to_i if amount.positive?

    self.xp += amount
    self.xp = 0 if self.xp.negative? # xp can never be less than 0
    self.xp = User::MAX_XP if self.xp > User::MAX_XP # don't exceed xp limit, this enforces max level = 100
    set_level
    save!
    {
      prev_xp: prev_xp,
      current_xp: self.xp,
      xp_diff: self.xp - prev_xp,
      xp_changed: self.xp != prev_xp,
      prev_level: prev_level,
      current_level: level,
      level_diff: level - prev_level,
      level_changed: level != prev_level
    }
  end

  def gains_loot(loot_container)
    throw('not a loot container') unless loot_container.is_a? LootContainer

    gains_or_loses_gold(loot_container.gold) if loot_container.gold.positive?
    loot_container.items.each do |item|
      gain_item item
    end
  end

  def death_xp_penalty
    -(
      (0.02 * self.xp) + (100 * (level - 1))
    )
  end

  def handle_death
    inventory_changes = {
      inventory_lost: false,
      equipment_lost: false,
      amulet_of_loss_consumed: false,
      amulet_of_life_consumed: false,
    }

    if amulet_of_life.present?
      xp_level_change = gains_or_loses_xp(0)
      amulet_of_life.destroy!
      inventory_changes[:amulet_of_life_consumed] = true
    else
      xp_level_change = gains_or_loses_xp(death_xp_penalty)

      if amulet_of_loss.present?
        amulet_of_loss.destroy!
        inventory_changes[:amulet_of_loss_consumed] = true
      else
        inventory_items.where(is_equipped: false).destroy_all
        inventory_changes[:inventory_lost] = true

        # 10% chance of equipment loss
        if equipped_items.empty? == false && rand(1..10) == 1
          equipped_items.sample.destroy!
          inventory_changes[:equipment_lost] = true
        end
      end
    end

    [xp_level_change, inventory_changes]
  end

  def give_starting_equipment
    starting_equipment = ['Shortsword', 'Leather Armor', 'Brass Helmet'] # Changing this may result in failing tests
    #starting_equipment += ['Angelic Axe', 'Amulet of Loss', 'Amulet of Life', 'Amulet of Abundance', 'Ring of Treasure Hunter', 'Relic Sword', 'Shield of Destiny'] if Rails.env.development?

    starting_equipment.each do |item_name|
      item = Item.find_by(name: item_name)
      throw("No such item as #{item_name}") if item.nil?
      inventory_item = gain_item(item)
      equip_item(inventory_item, true)
    end

    gains_or_loses_gold 10
  end

  def construct_base_at(point)
    raise('User already owns a structure') if base.present?

    real_world_location = RealWorldLocation.new(
      type: 'user_owned',
      coordinates: point,
    )
    raise('Failed to validate real world location') unless real_world_location.valid?

    real_world_location.save!
    self.base = Base.create!(
      user: self,
      real_world_location: real_world_location,
    )
  end

  protected

  def valid_auth0_user_data
    errors.add(:auth0_user_data, 'is missing property sub') if auth0_user_data.sub.nil?
    errors.add(:auth0_user_data, 'is missing property given_name') if auth0_user_data.given_name.nil?
    errors.add(:auth0_user_data, 'is missing property family_name') if auth0_user_data.family_name.nil?
    # errors.add(:auth0_user_data, 'is missing property email') if auth0_user_data.email.nil?
  end

  def access_token_expires
    if access_token.present? && access_token_expires_at.nil?
      errors.add(:base, 'access token without expiration date is not allowed')
    end
  end

  private

  def achievements_are_valid
    # Should have only valid types
    achievements.each do |a|
      errors.add(:tags, "contains an invalid achievement '#{a}'") unless a.in? ACHIEVEMENTS
    end
  end
end
