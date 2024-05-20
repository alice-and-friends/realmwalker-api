# frozen_string_literal: true

class DungeonExpirationWorker
  include Sidekiq::Job
  sidekiq_options queue: 'environment-normal'

  def perform(dungeon_id)
    Dungeon.find(dungeon_id).expired!

    puts '🟠 Expired 1 dungeons.'
  end
end
