# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

require 'csv'

puts 'Seeding the database...'

# CREATE REAL WORLD LOCATIONS
filename = 'real_world_locations.csv'
filename = 'real_world_locations_oslo.csv' if Rails.env.development?
csv_text = File.read(Rails.root.join('lib', 'seeds', filename))
csv = CSV.parse(csv_text, :headers => true, :encoding => 'ISO-8859-1')
csv.each do |row|
  loc = RealWorldLocation.new()
  loc.name = row['name']
  loc.ext_id = row['ext_id']
  loc.type = row['type']
  loc.type = 'shop' if loc.ext_id[-2..].in? %w[00 01]
  loc.coordinates = ActiveRecord::Point.new(row['lat'], row['lon'])

  puts loc.errors.inspect unless loc.save
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

  puts mon.errors.inspect unless mon.save
end
puts "🌱 Seeded #{Monster.count} monsters."

# CREATE ITEMS
csv_text = File.read(Rails.root.join('lib', 'seeds', 'items.csv'))
csv = CSV.parse(csv_text, :headers => true, :encoding => 'ISO-8859-1')
csv.each do |row|
  item = Item.new
  item.name = row['name']
  item.type = row['type'].downcase.gsub(' ', '_')

  # Lootable
  item.rarity = row['rarity'].downcase
  item.dropped_by_classification = row['dropped_by_classification']&.split(', ')
  item.dropped_by_level = row['dropped_by_level']
  item.drop_max_amount = row['drop_max_amount']

  # Equipable
  item.two_handed = row['two_handed']
  item.attack_bonus = row['attack_bonus']
  item.defense_bonus = row['defense_bonus']
  item.classification_bonus = row['classification_bonus']
  item.classification_attack_bonus = row['classification_attack_bonus']
  item.classification_defense_bonus = row['classification_defense_bonus']
  item.xp_bonus = row['xp_bonus']
  item.loot_bonus = row['loot_bonus']

  # Tradable
  item.armorer_buy = row['armorer_buy']&.delete('^0-9')
  item.armorer_sell = row['armorer_sell']&.delete('^0-9')
  item.jeweller_buy = row['jeweller_buy']&.delete('^0-9')
  item.jeweller_sell = row['jeweller_sell']&.delete('^0-9')
  item.magic_shop_buy = row['magic_shop_buy']&.delete('^0-9')
  item.magic_shop_sell = row['magic_shop_sell']&.delete('^0-9')

  puts item.errors.inspect unless item.save
end
puts "🌱 Seeded #{Item.count} items."

# CREATE SHOPS
RealWorldLocation.where(type: 'shop').pluck(:id).each do |rwl_id|
  last_digit = rwl_id.digits[0]
  shop_type = if last_digit.in? 0..2
                'magic'
              elsif last_digit.in? 3..5
                'jeweller'
              else
                'armorer'
              end
  npc = Npc.new({
                  role: 'shopkeeper',
                  shop_type: shop_type,
                  real_world_location_id: rwl_id,
                })

  unless npc.save
    puts npc.errors.inspect
  end
end
puts "🌱 Seeded #{Npc.where(role: 'shopkeeper').count} shops."

return if Rails.env.production?

# CREATE DUNGEONS
Dungeon.max_dungeons.times do |counter|
  d = Dungeon.new({
                    created_at: (counter * 2).hours.ago,
                    status: Dungeon.statuses[:active] ##rand(2).odd? ? Dungeon.statuses[:active] : Dungeon.statuses[:defeated]
                  })
  d.save!
end
# Rake::Task["dungeon:despawn"].execute

# CREATE NPCS
# 3.times do |counter|
#   npc = Npc.new({
#                   created_at: (counter*12).hours.ago,
#                 })
#   npc.save!
# end
