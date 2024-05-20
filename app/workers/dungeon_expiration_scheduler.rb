# frozen_string_literal: true

class DungeonExpirationScheduler
  include Sidekiq::Job
  sidekiq_options queue: 'slow'

  def perform
    initial_count = Dungeon.where(expiry_job_id: nil).count

    # Expire dungeons that have been active for too long
    Dungeon.active
           .where(expiry_job_id: nil)
           .where('created_at < ?', Dungeon::ACTIVE_DURATION.ago)
           .find_each(&:schedule_expiration!)

    # Expire dungeons that have been defeated for too long
    Dungeon.defeated
           .where(expiry_job_id: nil)
           .where('defeated_at < ?', Dungeon::DEFEATED_DURATION.ago)
           .find_each(&:schedule_expiration!)

    # Expire night time monsters when it's day
    night_zones = Dungeon.night_time_zones
    night_monsters = Monster.night_only
    Dungeon.active
           .where(expiry_job_id: nil)
           .where(timezone: night_zones, monster: night_monsters)
           .find_each(&:schedule_expiration!)

    # Expire day time monsters when it's night
    day_zones = Dungeon.day_time_zones
    day_monsters = Monster.day_only
    Dungeon.active
           .where(expiry_job_id: nil)
           .where(timezone: day_zones, monster: day_monsters)
           .find_each(&:schedule_expiration!)


    new_count = Dungeon.where(expiry_job_id: nil).count

    total = initial_count - new_count
    puts "⏰ Scheduled #{total} dungeon expirations." if total.positive?
  end
end
