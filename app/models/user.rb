class User < ApplicationRecord
  #store_accessor :preferences, :language
  #store_accessor :preferences, :voice

  serialize :auth0_user_data, Auth0UserData

  validates :auth0_user_id, presence: true, uniqueness: true
  validate :valid_auth0_user_data

  XP_CAP = 1000000
  def self.total_exp_needed_for_level(l)
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

  def set_level
    # Check if current level is accurate
    current_level_xp_req = User::total_exp_needed_for_level(self.level)
    next_level_xp_req = User::total_exp_needed_for_level(self.level+1)
    if self.xp >= current_level_xp_req and self.xp < next_level_xp_req
      puts "Current level is appropriate"
      return
    end

    # Calculate new level
    n = 1
    while User::total_exp_needed_for_level(n) <= self.xp
      puts "User has #{self.xp} which is enough for at least level #{n}"
      n += 1
    end
    self.level = n-1
  end

  def xp_level_report
    next_level_at = User::total_exp_needed_for_level(self.level+1)
    levels_xp_diff = User::total_exp_needed_for_level(self.level+1) - User::total_exp_needed_for_level(self.level)
    level_xp_surplus = self.xp - User::total_exp_needed_for_level(self.level)
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
    puts "Death resulting in #{xp_loss} xp lost"
    xp_change = gains_or_loses_xp(xp_loss*-1)
  end

  protected

  def valid_auth0_user_data
    errors.add(:auth0_user_data, 'is missing property sub') if auth0_user_data.sub.nil?
    errors.add(:auth0_user_data, 'is missing property given_name') if auth0_user_data.given_name.nil?
    errors.add(:auth0_user_data, 'is missing property family_name') if auth0_user_data.family_name.nil?
    # errors.add(:auth0_user_data, 'is missing property email') if auth0_user_data.email.nil?
  end
end
