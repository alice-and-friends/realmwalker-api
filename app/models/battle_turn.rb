# frozen_string_literal: true

class BattleTurn < ApplicationRecord
  belongs_to :battle
  belongs_to :actor, polymorphic: true # User or Dungeon
  belongs_to :target, polymorphic: true # User or Dungeon

  enum status: {
    waiting_on_actor: 'waiting_on_actor',
    committed: 'committed',
    completed: 'completed',
  }, _prefix: :turn

  validate :must_have_completed_previous_turn, on: :create
  validates :sequence, :status, presence: true

  before_validation :set_initial_values, on: :create
  around_update :lock_battle_and_sync_timestamp
  around_create :lock_battle_and_sync_timestamp

  def description
    "#{actor.name} used #{action}."
  end

  def must_have_completed_previous_turn
    return if battle.turns.empty? # Allow the first turn
    return if battle.turns.last.status == self.class.statuses[:completed]

    errors.add(:base, 'Cannot create new turn until the previous turn is completed') # This text is tested
  end

  private

  def set_initial_values
    self.status ||= self.class.statuses[:waiting_on_actor]
    self.sequence ||= 1
  end

  def lock_battle_and_sync_timestamp
    Battle.transaction do
      battle.lock!

      yield

      # Re-read self.updated_at inside the transaction
      battle.touch(time: updated_at)
    end
  end
end
