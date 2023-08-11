class User < ApplicationRecord
  has_many :inventory_items, :dependent => :delete_all
  has_many :items, through: :inventory_items

  ACHIEVEMENTS = %w[]

  serialize :auth0_user_data, Auth0UserData

  after_create :give_starting_equipment
  validates :auth0_user_id, presence: true, uniqueness: true
  validate :valid_auth0_user_data
  validate :achievements_are_valid

  XP_CAP = 1000000
  def self.total_xp_needed_for_level(l)
    (10*(l-1))**2 + ((l-1)*100)
  end

  def email
    auth0_user_data.email
  end
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
  def equip_item(inventory_item, force=false)
    max_items_of_type = inventory_item.item.type == 'ring' ? 2 : 1
    items_to_unequip = []

    # NB: You probably don't change the order of these checks
    equipped_items_of_this_type = equipped_items.where("items.type": inventory_item.item.type)
    if inventory_item.item.two_handed == true
      items_to_unequip += equipped_items.where("type IN (?)", ['weapon', 'shield'])
    elsif equipped_items_of_this_type.count >= max_items_of_type
      if max_items_of_type > 1
        items_to_unequip << equipped_items_of_this_type.first
      else
        items_to_unequip += equipped_items_of_this_type
      end
    elsif inventory_item.item.type == 'shield'
      items_to_unequip += equipped_items.where("items.two_handed": true)
    end

    if items_to_unequip.length.zero?
      inventory_item.update!(is_equipped: true)
      return true, []
    else
      if force
        items_to_unequip.each do |unequip_this|
          self.unequip_item(unequip_this)
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

  def set_level
    # Check if current level is accurate
    current_level_xp_req = User::total_xp_needed_for_level(self.level)
    next_level_xp_req = User::total_xp_needed_for_level(self.level+1)
    if self.xp >= current_level_xp_req and self.xp < next_level_xp_req
      return
    end

    # Calculate new level
    n = 1
    while User::total_xp_needed_for_level(n) <= self.xp
      n += 1
    end
    self.level = n-1
  end

  def xp_level_report
    next_level_at = User::total_xp_needed_for_level(self.level+1)
    levels_xp_diff = User::total_xp_needed_for_level(self.level+1) - User::total_xp_needed_for_level(self.level)
    level_xp_surplus = self.xp - User::total_xp_needed_for_level(self.level)
    {
      xp: self.xp,
      level: self.level,
      next_level_at: next_level_at,
      to_next_level: next_level_at - self.xp,
      next_level_progress: (level_xp_surplus.to_f / levels_xp_diff.to_f * 100.0).floor
    }
  end

  def gains_or_loses_xp(n)
    prev_xp = self.xp.freeze
    prev_level = self.level.freeze

    self.xp += n
    self.xp = 0 if self.xp < 0 # xp can never be less than 0
    self.xp = User::XP_CAP if self.xp > User::XP_CAP # don't exceed xp limit, this enforces max level = 100
    self.set_level
    save!
    {
      prev_xp: prev_xp,
      current_xp: self.xp,
      xp_diff: self.xp - prev_xp,
      xp_changed: self.xp != prev_xp,
      prev_level: prev_level,
      current_level: self.level,
      level_diff: self.level - prev_level,
      level_changed: self.level != prev_level
    }
  end

  def dies
    xp_loss = (0.02*self.xp)+(100*(self.level-1))
    xp_change = gains_or_loses_xp(xp_loss*-1)
  end

  def give_starting_equipment
    ['Shortsword', 'Leather Armor', 'Iron Helmet'].each do |item_name|
    #['Amulet of Abundance', 'Ring of Treasure Hunter', 'Angelic Axe', 'Demon Shield', 'Prismatic Helmet', 'Scale Armor'].each do |item_name|
      item = Item.find_by(name: item_name)
      inventory_item = self.gain_item(item)
      self.equip_item(inventory_item)
    end
    ['Angelic Axe'].each do |item_name|
      item = Item.find_by(name: item_name)
      self.gain_item(item)
    end
  end

  private
  def achievements_are_valid
    # Should have only valid types
    achievements.each do |a|
      unless a.in? ACHIEVEMENTS
        errors.add(:tags, "contains an invalid achievement '#{a}'")
      end
    end
  end

  protected
  def valid_auth0_user_data
    errors.add(:auth0_user_data, 'is missing property sub') if auth0_user_data.sub.nil?
    errors.add(:auth0_user_data, 'is missing property given_name') if auth0_user_data.given_name.nil?
    errors.add(:auth0_user_data, 'is missing property family_name') if auth0_user_data.family_name.nil?
    # errors.add(:auth0_user_data, 'is missing property email') if auth0_user_data.email.nil?
  end
end
