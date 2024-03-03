# frozen_string_literal: true

class DungeonExpirationScheduler
  include Sidekiq::Job

  def perform
    initial_count = Dungeon.where(expiry_job_id: nil).count

    Dungeon.active
           .where(expiry_job_id: nil)
           .where('created_at < ?', Dungeon::ACTIVE_DURATION.ago)
           .find_each(&:schedule_expiration!)

    Dungeon.defeated
           .where(expiry_job_id: nil)
           .where('defeated_at < ?', Dungeon::DEFEATED_DURATION.ago)
           .find_each(&:schedule_expiration!)

    new_count = Dungeon.where(expiry_job_id: nil).count

    total = initial_count - new_count
    puts "⏰ Scheduled #{total} dungeon expirations." if total.positive?
  end
end
