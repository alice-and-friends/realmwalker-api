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
  mon.classification = row['classification']
  #mon.tags = row['tags'].split(' ')
  unless mon.save
    puts mon.errors.inspect
  end
end
puts "🌱 Seeded #{Monster.count} monsters."

# CREATE ITEMS
csv_text = File.read(Rails.root.join('lib', 'seeds', 'items.csv'))
csv = CSV.parse(csv_text, :headers => true, :encoding => 'ISO-8859-1')
csv.each do |row|
  item = Item.new()
  item.name = row['name']
  item.type = row['type'].downcase
  item.rarity = row['rarity'].downcase
  item.dropped_by_classification = row['dropped_by_classification'].split(', ')
  item.dropped_by_level = row['dropped_by_level']
  item.two_handed = row['two_handed']
  item.attack_bonus = row['attack_bonus']
  item.defense_bonus = row['defense_bonus']
  item.classification_bonus = row['classification_bonus']
  item.classification_attack_bonus = row['classification_attack_bonus']
  item.classification_defense_bonus = row['classification_defense_bonus']
  item.xp_bonus = row['xp_bonus']
  item.loot_bonus = row['loot_bonus']
  item.npc_buy = row['npc_buy']
  item.npc_sell = row['npc_sell']
  unless item.save
    puts 'seed error:', item.inspect, item.errors.inspect
  end
end
puts "🌱 Seeded #{Item.count} items."

# CREATE DUNGEONS
20.times do |counter|
  d = Dungeon.new({
                    created_at: (counter*2).hours.ago,
                    status: Dungeon.statuses[:active] ##rand(2).odd? ? Dungeon.statuses[:active] : Dungeon.statuses[:defeated]
                  })
  d.save!
end
# Rake::Task["dungeon:despawn"].execute

# CREATE NPCS
3.times do |counter|
  npc = Npc.new({
                  created_at: (counter*12).hours.ago,
                })
  npc.save!
end
