# frozen_string_literal: true

class User < ApplicationRecord
  has_many :inventory_items, dependent: :delete_all
  has_many :items, through: :inventory_items

  BASE_ATTACK = 10.freeze
  ACHIEVEMENTS = %w[].freeze

  serialize :auth0_user_data, Auth0UserData

  after_create :give_starting_equipment
  validates :auth0_user_id, presence: true, uniqueness: true
  validate :valid_auth0_user_data
  validate :achievements_are_valid

  XP_CAP = 1_000_000
  def self.total_xp_needed_for_level(l)
    ((10 * (l - 1))**2) + ((l - 1) * 100)
  end

  delegate :email, to: :auth0_user_data

  def name
    auth0_user_data.given_name
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

  def amulet_of_loss?
    equipped_items.find_by(items: { name: 'Amulet of Loss' }).present?
  end

  def amulet_of_life?
    equipped_items.find_by(items: { name: 'Amulet of Life' }).present?
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
    return if xp >= current_level_xp_req and xp < next_level_xp_req

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
      next_level_progress: (level_xp_surplus.to_f / levels_xp_diff.to_f * 100.0).floor
    }
  end

  def gains_or_loses_xp(n)
    prev_xp = xp.freeze
    prev_level = level.freeze

    self.xp += n
    self.xp = 0 if self.xp.negative? # xp can never be less than 0
    # don't exceed xp limit, this enforces max level = 100
    self.xp = User::XP_CAP if self.xp > User::XP_CAP
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

  def dies
    raise 'dies called for user wearing amulet of life, always check for amulet before calling.' if amulet_of_life?

    xp_loss = -1 * (
      (0.02 * self.xp) + (100 * (level - 1))
    )
    gains_or_loses_xp(xp_loss)
  end

  def give_starting_equipment
    ['Shortsword', 'Leather Armor', 'Iron Helmet'].each do |item_name|
    #['Amulet of Abundance', 'Ring of Treasure Hunter', 'Angelic Axe', 'Demon Shield', 'Prismatic Helmet', 'Scale Armor'].each do |item_name|
      item = Item.find_by(name: item_name)
      inventory_item = gain_item(item)
      equip_item(inventory_item)
    end
    ['Angelic Axe'].each do |item_name|
      item = Item.find_by(name: item_name)
      gain_item(item)
    end
  end

  protected

  def valid_auth0_user_data
    errors.add(:auth0_user_data, 'is missing property sub') if auth0_user_data.sub.nil?
    errors.add(:auth0_user_data, 'is missing property given_name') if auth0_user_data.given_name.nil?
    errors.add(:auth0_user_data, 'is missing property family_name') if auth0_user_data.family_name.nil?
    # errors.add(:auth0_user_data, 'is missing property email') if auth0_user_data.email.nil?
  end

  private

  def achievements_are_valid
    # Should have only valid types
    achievements.each do |a|
      errors.add(:tags, "contains an invalid achievement '#{a}'") unless a.in? ACHIEVEMENTS
    end
  end
end
