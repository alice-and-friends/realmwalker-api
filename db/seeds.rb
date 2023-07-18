# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

require 'csv'

# CREATE REAL WORLD LOCATIONS
csv_text = File.read(Rails.root.join('lib', 'seeds', 'real_world_locations.csv'))
csv = CSV.parse(csv_text, :headers => true, :encoding => 'ISO-8859-1')
csv.each do |row|
  loc = RealWorldLocation.new()
  loc.name = row['name']
  loc.ext_id = row['ext_id']
  loc.type = row['type']
  loc.coordinates = ActiveRecord::Point.new(row['lat'], row['lon'])
  unless loc.save
    puts loc.errors.inspect
  end
end
puts "🌱 Seeded #{RealWorldLocation.count} real world locations."

# CREATE MONSTERS
csv_text = File.read(Rails.root.join('lib', 'seeds', 'monsters.csv'))
csv = CSV.parse(csv_text, :headers => true, :encoding => 'ISO-8859-1')
csv.each do |row|
  mon = Monster.new()
  mon.name = row['name']
  mon.description = row['description']
  mon.level = row['level']
  unless mon.save
    puts mon.errors.inspect
  end
end
puts "🌱 Seeded #{Monster.count} monsters."

# CREATE DUNGEONS
30.times do |counter|
  d = Dungeon.new({
                    created_at: (counter*2).hours.ago,
                    status: rand(2).odd? ? Dungeon.statuses[:active] : Dungeon.statuses[:defeated]
                  })
  d.save!
end
Rake::Task["dungeon:despawn"].execute

# CREATE NPCS
3.times do |counter|
  npc = Npc.new({
                  created_at: (counter*12).hours.ago,
                })
  npc.save!
end
