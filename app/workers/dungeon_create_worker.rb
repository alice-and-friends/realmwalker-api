# frozen_string_literal: true

class DungeonCreateWorker
  include Sidekiq::Job

  BATCH_SIZE = 100

  def perform
    all_known_regions = RealWorldLocation.distinct.pluck(:region)
    active_dungeons_count = Dungeon.active.group(:region).count

    all_known_regions.each do |region|
      active_dungeons = active_dungeons_count[region] || 0
      expected_dungeons = Dungeon.min_active_dungeons(region)
      missing_dungeons = expected_dungeons - active_dungeons
      next unless missing_dungeons >= 1

      # Create new dungeons in the region
      new_dungeons = []
      new_dungeon_location_ids = RealWorldLocation.available.for_dungeon.where(region: region).order('RANDOM()').limit(missing_dungeons).pluck(:id)
      missing_dungeons = 100 if missing_dungeons > BATCH_SIZE # Upper limit for dungeons created at once
      missing_dungeons.times do
        new_dungeons << Dungeon.new(
          real_world_location_id: new_dungeon_location_ids.pop,
          created_at: rand(0..200).seconds.ago, # Introduce some variance, to avoid everything getting expired and respawned at the same time
        )
      end
      Dungeon.import!(new_dungeons, batch_size: BATCH_SIZE, validate: true)

      puts "📌 Spawned #{missing_dungeons} dungeons in #{region}."
    end
  end
end
