# frozen_string_literal: true

class DungeonExpirationWorker
  include Sidekiq::Job

  def perform(dungeon_id)
    Dungeon.find(dungeon_id).expired!
  end
end
