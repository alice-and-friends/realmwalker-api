# frozen_string_literal: true

class DungeonCreateWorker
  include Sidekiq::Job

  def perform
    Dungeon.create!
  end
end
