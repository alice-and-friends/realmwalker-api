# frozen_string_literal: true

class DungeonDestroyWorker
  include Sidekiq::Job

  def perform
    destroyed_dungeons = Dungeon.expired.where('expires_at < ?', Dungeon::EXPIRED_DURATION.ago).destroy_all

    puts "❌ Destroyed #{destroyed_dungeons.count} dungeons."
  end
end
