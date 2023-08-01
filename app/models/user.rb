class User < ApplicationRecord
  has_many :inventory_items
  has_many :items, through: :inventory_items

  ACHIEVEMENTS = %w[]

  serialize :auth0_user_data, Auth0UserData

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
  def given_name
    auth0_user_data.given_name
  end
  def family_name
    auth0_user_data.family_name
  end

  def equipped_items
    inventory_items.where(is_equipped: true).map(&:items)
  end
  def gain_item(item)
    inventory_items.create(item: item)
  end
  def lose_item(item)
    inventory_items.find_by(item: item).destroy
  end
  def equip_item(item)
    equipment_item = inventory_items.find_by(item: item)
    equipment_item.update(is_equipped: true)
  end
  def unequip_item(item)
    equipment_item = inventory_items.find_by(item: item)
    equipment_item.update(is_equipped: false)
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
      next_level_progress: level_xp_surplus.to_f / levels_xp_diff.to_f * 100.0
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
