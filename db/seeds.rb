# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

require 'csv'
include Species
include Gender

puts 'Seeding the database...'

execution_time = Benchmark.measure do

  # CREATE REAL WORLD LOCATIONS
  locations = []
  filename = 'real_world_locations.csv'
  # filename = 'real_world_locations_oslo.csv' if Rails.env.development?
  csv_text = Rails.root.join('lib', 'seeds', filename).read
  csv = CSV.parse(csv_text, headers: true, encoding: 'ISO-8859-1')
  csv.each do |row|
    location = RealWorldLocation.new(
      name: row['name'],
      ext_id: row['ext_id'],
      type: row['type'],
      # coordinates: ActiveRecord::Point.new(row['lat'], row['lon']),
      coordinates: "POINT(#{row['lat']} #{row['lon']})",
    )
    location.type = 'shop' if location.ext_id[-2..].in? %w[00 01]
    locations << location
    puts location.errors.inspect, location.coordinates unless location.valid?
  end
  RealWorldLocation.import locations
  puts "🌱 Seeded #{RealWorldLocation.count} real world locations."

  # CREATE MONSTERS
  monsters = []
  csv_text = Rails.root.join('lib/seeds/monsters.csv').read
  csv = CSV.parse(csv_text, headers: true, encoding: 'ISO-8859-1')
  csv.each do |row|
    monster = Monster.new()
    monster.name = row['name']
    monster.description = row['description']
    monster.level = row['level']
    monster.classification = row['classification']
    # monster.tags = row['tags'].split(' ')
    monsters << monster
  end
  Monster.import monsters
  puts "🌱 Seeded #{Monster.count} monsters."

  # CREATE ITEMS
  armorer_offer_list = TradeOfferList.find_or_create_by(name: 'armorer')
  jeweller_offer_list = TradeOfferList.find_or_create_by(name: 'jeweller')
  magic_shop_offer_list = TradeOfferList.find_or_create_by(name: 'magic shop')

  csv_text = Rails.root.join('lib/seeds/items.csv').read
  csv = CSV.parse(csv_text, headers: true, encoding: 'ISO-8859-1')
  csv.each do |row|
    item = Item.new
    item.name = row['name']
    item.type = row['type'].downcase.tr(' ', '_')
    item.icon = row['icon']

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

    unless item.save
      puts "🛑 #{item.errors.inspect}"
      next
    end

    # Tradable
    if row['armorer_buy'] || row['armorer_sell']
      trade_offer = TradeOffer.new(item: item)
      trade_offer.buy_offer = row['armorer_buy']&.delete('^0-9') if row['armorer_buy'].present?
      trade_offer.sell_offer = row['armorer_sell']&.delete('^0-9') if row['armorer_sell'].present?
      if trade_offer.save
        armorer_offer_list.trade_offers << trade_offer
      else
        puts "🛑 #{trade_offer.errors.inspect}"
      end
    end
    if row['jeweller_buy'] || row['jeweller_sell']
      trade_offer = TradeOffer.new(item: item)
      trade_offer.buy_offer = row['jeweller_buy']&.delete('^0-9') if row['jeweller_buy'].present?
      trade_offer.sell_offer = row['jeweller_sell']&.delete('^0-9') if row['jeweller_sell'].present?
      if trade_offer.save
        jeweller_offer_list.trade_offers << trade_offer
      else
        puts "🛑 #{trade_offer.errors.inspect}"
      end
    end
    if row['magic_shop_buy'] || row['magic_shop_sell']
      trade_offer = TradeOffer.new(item: item)
      trade_offer.buy_offer = row['magic_shop_buy']&.delete('^0-9') if row['magic_shop_buy'].present?
      trade_offer.sell_offer = row['magic_shop_sell']&.delete('^0-9') if row['magic_shop_sell'].present?
      if trade_offer.save
        magic_shop_offer_list.trade_offers << trade_offer
      else
        puts "🛑 #{trade_offer.errors.inspect}"
      end
    end
  end
  puts "🌱 Seeded #{Item.count} items."
  puts "🌱 Seeded #{TradeOffer.count} trade offers."
  puts "🌱 Seeded #{TradeOfferList.count} trade offer lists."

  # CREATE PORTRAITS
  portraits = []
  # portraits << Portrait.new(name: 'alchemist', species: %w[human elf dwarf giant troll goblin kenku], genders: %w[f m x], groups: %w[armorer jeweller magic])
  portraits << Portrait.new(name: 'barbarian', species: %w[human elf], genders: %w[m x], groups: %w[armorer])
  portraits << Portrait.new(name: 'barbute', species: %w[human elf dwarf giant troll goblin kenku], genders: %w[m x], groups: %w[armorer])
  portraits << Portrait.new(name: 'bird-mask', species: %w[human goblin kenku], genders: %w[f m x], groups: %w[jeweller magic])
  portraits << Portrait.new(name: 'cleo', species: %w[human elf], genders: %w[f x], groups: %w[jeweller magic])
  portraits << Portrait.new(name: 'cowled', species: %w[human elf goblin kenku], genders: %w[f m x], groups: %w[armorer jeweller magic])
  portraits << Portrait.new(name: 'dwarf', species: %w[dwarf], genders: %w[f m x], groups: %w[armorer jeweller])
  portraits << Portrait.new(name: 'elf', species: %w[elf], genders: %w[f m x], groups: %w[jeweller])
  portraits << Portrait.new(name: 'eyepatch', species: %w[human], genders: %w[m], groups: %w[jeweller])
  portraits << Portrait.new(name: 'kenku', species: %w[kenku], genders: %w[f m x], groups: %w[armorer jeweller magic])
  portraits << Portrait.new(name: 'monk', species: %w[human dwarf giant], genders: %w[m], groups: %w[armorer jeweller magic])
  portraits << Portrait.new(name: 'nun', species: %w[human elf dwarf giant], genders: %w[f], groups: %w[armorer jeweller magic])
  portraits << Portrait.new(name: 'pig-face', species: %w[human], genders: %w[m], groups: %w[armorer])
  portraits << Portrait.new(name: 'pig-face', species: %w[giant troll], genders: %w[f m x], groups: %w[armorer jeweller magic])
  portraits << Portrait.new(name: 'troll', species: %w[giant troll], genders: %w[m], groups: %w[armorer])
  portraits << Portrait.new(name: 'vampire', species: %w[human elf], genders: %w[f], groups: %w[magic])
  portraits << Portrait.new(name: 'witch', species: %w[human elf dwarf giant troll goblin], genders: %w[f], groups: %w[magic])
  portraits << Portrait.new(name: 'wizard', species: %w[human dwarf], genders: %w[m x], groups: %w[magic])
  # portraits << Portrait.new(name: '', species: %w[human elf dwarf giant troll goblin kenku], genders: %w[f m x], groups: %w[armorer jeweller magic])
  Portrait.import portraits
  Species::SPECIES.each do |species|
    Gender::GENDERS.each do |gender|
      Npc::SHOP_TYPES.each do |group|
        test = Portrait.find_by(':species = ANY(species) AND :gender = ANY(genders) and :group = ANY(groups)',
                         species: species, gender: gender, group: group)
        # puts "#{test.count} portrait options for #{species} #{gender} #{group}"
        puts "⚠️ Warning: No portrait match for #{species} #{gender} #{group}" if test.nil?
      end
    end
  end
  puts "🌱 Seeded #{Portrait.count} portraits."

  # CREATE SHOPS
  RealWorldLocation.where(type: 'shop').pluck(:id).each do |rwl_id|
    last_digit = rwl_id.digits[0]
    npc = Npc.new({
                    role: 'shopkeeper',
                    real_world_location_id: rwl_id,
                  })

    if last_digit.in? 0..2
      npc.shop_type = 'magic'
      npc.trade_offer_lists << magic_shop_offer_list
    elsif last_digit.in? 3..5
      npc.shop_type = 'jeweller'
      npc.trade_offer_lists << jeweller_offer_list
    else
      npc.shop_type = 'armorer'
      npc.trade_offer_lists << armorer_offer_list
    end

    unless npc.save
      puts "🛑 #{npc.errors.inspect}"
    end
  end
  puts "🌱 Seeded #{Npc.where(role: 'shopkeeper').count} shops."

  return if Rails.env.production?

  # CREATE DUNGEONS
  Dungeon.max_dungeons.times do |counter|
    d = Dungeon.new({
                      created_at: counter.hours.ago,
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

end
puts "Completed seeding in #{execution_time.real.round(2)} seconds."
