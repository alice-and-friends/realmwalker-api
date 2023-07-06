namespace :dungeon  do
  task despawn: :environment do
    # If any dungeons have been active for 48 hours, despawn them
    Location.active.where("created_at < ?", 2.days.ago).destroy_all
    # If any dungeons have been defeated for a week, despawn them
    Location.defeated.where("updated_at < ?", 7.days.ago).destroy_all
  end
  task spawn: :environment do
    # Create a new dungeon if the current active count is below desired
    if Location.active.count < 10
      Location.generate_dungeon!
    end
  end
end
