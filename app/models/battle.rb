# frozen_string_literal: true

class Battle < ApplicationRecord
  belongs_to :monster, optional: true
  belongs_to :player, class_name: 'User'
  belongs_to :opponent, polymorphic: true # User or Dungeon
  has_many :battle_turns, dependent: :delete_all
  alias_attribute :turns, :battle_turns

  enum status: {
    ongoing: 'ongoing',
    completed: 'completed',
    abandoned: 'abandoned',
  }, _prefix: :battle

  validate :opponent_is_of_allowed_class, on: :create
  validate :must_fight_one_battle_at_a_time, on: :create
  # validate :must_have_monster, if: :dungeon?
  # before_validation :set_monster, on: :create, if: :dungeon?

  before_validation :set_defaults, on: :create
  after_create :initiate_next_turn!

  scope :ongoing, -> { where(status: Battle.statuses[:ongoing]) }
  scope :stale, -> { ongoing.where('updated_at < ?', 1.hour.ago) }

  def self.valid_opponent_type?(type)
    type.in? %w[User Dungeon]
  end

  def initiate_next_turn!
    if turns.any?
      last_turn = turns.last
      raise "Can't initiate next turn because current turn still ongoing (#{last_turn.status})." unless last_turn.turn_completed?

      turns.create!(actor: last_turn.target, target: last_turn.actor, sequence: last_turn.sequence + 1)
    else
      turns.create!(actor: player, target: opponent)
    end
  rescue StandardError => e
    Rails.logger.error("Failed to initiate turn: #{e.message}")
    raise
  end

  def current_turn
    return unless battle_ongoing?

    turns.last
  end

  # def dungeon?
  #   opponent_type == 'Dungeon'
  # end

  private

  def set_defaults
    self.status = self.class.statuses[:ongoing] if status.blank?
  end

  def must_fight_one_battle_at_a_time
    ongoing_battles = player.battles.ongoing.pluck(:id)
    return if ongoing_battles.empty?

    errors.add(:player, "Cannot start battle, is already in ongoing battle(s): #{ongoing_battles}")
  end

  def opponent_is_of_allowed_class
    return if Battle.valid_opponent_type? opponent.class.name

    errors.add(:opponent, 'class not allowed for association')
  end

  # def set_monster
  #   self.monster = realm_location.monster if realm_location.present?
  # end
  #
  # def must_have_monster
  #   errors.add(:monster_id, 'can\'t be blank') if monster_id.nil?
  # end
end
