namespace :dungeon  do
  task despawn: :environment do
    puts 'Running Despawn task...'

    # If any dungeons have been defeated for an hour, destroy them.
    # Defeated dungeons don't need a cooldown period because they are replaced by battlefields.
    # set = Dungeon.defeated.where("defeated_at < ?", 1.hour.ago).destroy_all
    # if set.count
    #   puts "#{set.count} defeated dungeons destroyed"
    # end

    # If any dungeons have been active for 48 hours, disable them and begin a cooldown period
    set = Dungeon.active.where("created_at < ?", 2.days.ago)
    if set.count
      puts "#{set.count} active dungeon expired"
      set.update_all(status: Dungeon.statuses[:expired])
    end

    # If any dungeons have been expired for 48 hours, end the cooldown period by destroying the record
    set = Dungeon.expired.where("updated_at < ?", 2.days.ago)
    if set.count
      puts "#{set.count} expired dungeons destroyed"
      set.destroy_all
    end

    # If any battlefields have been active for 48 hours, disable them and begin a cooldown period
    set = Battlefield.active.where("updated_at < ?", 2.days.ago)
    if set.count
      puts "#{set.count} active battlefields expired"
      set.update_all(status: Battlefield.statuses[:expired])
    end

    # If any battlefields have been expired for 48 hours, end the cooldown period by destroying the record
    set = Battlefield.expired.where("updated_at < ?", 2.days.ago)
    if set.count
      puts "#{set.count} expired battlefields destroyed"
      set.destroy_all
    end
  end

  task spawn: :environment do
    # Create a new dungeon if the current active count is below desired
    if Dungeon.active.count < Dungeon.max_dungeons
      Dungeon.create!
    end
  end
end
