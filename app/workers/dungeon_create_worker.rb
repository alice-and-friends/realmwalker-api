# frozen_string_literal: true

class DungeonCreateWorker
  include Sidekiq::Job
  sidekiq_options queue: 'environment-normal'

  def perform
    all_known_regions = RealWorldLocation.distinct.pluck(:region)
    active_dungeons_count = Dungeon.active.group(:region).count

    all_known_regions.each do |region|
      active_dungeons = active_dungeons_count[region] || 0
      expected_dungeons = Dungeon.min_active_dungeons(region)
      missing_dungeons = expected_dungeons - active_dungeons
      next unless missing_dungeons >= 1

      # Create new dungeons in the region
      dungeon_specs = []
      batch_size = [missing_dungeons, 100].min # Upper limit for dungeons created at once
      RealWorldLocation.available.for_dungeon.where(region: region).order('RANDOM()').limit(batch_size).each do |rwl|
        dungeon_specs << {
          real_world_location_id: rwl.id,
          created_at: rand(0..200).seconds.ago, # Introduce some variance, to avoid everything getting expired and respawned at the same time
        }
      end
      Dungeon.create!(dungeon_specs)

      puts "📌 Spawned #{batch_size} dungeons in #{region}."
    end
  end
end
