# frozen_string_literal: true

class DungeonDestroyWorker
  include Sidekiq::Job

  def perform
    Dungeon.expired.where('updated_at < ?', Dungeon::EXPIRED_DURATION).destroy_all
  end
end
