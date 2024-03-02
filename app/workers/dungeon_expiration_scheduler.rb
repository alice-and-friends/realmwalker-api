# frozen_string_literal: true

class DungeonExpirationScheduler
  include Sidekiq::Job

  def perform
    Dungeon.active
           .where(expiry_job_id: nil)
           .where('created_at < ?', Dungeon::ACTIVE_DURATION.ago)
           .find_each(&:schedule_expiration!)

    Dungeon.defeated
           .where(expiry_job_id: nil)
           .where('defeated_at < ?', Dungeon::DEFEATED_DURATION.ago)
           .find_each(&:schedule_expiration!)
  end
end
