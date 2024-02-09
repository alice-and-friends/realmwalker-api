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

class SeedHelper
  @batch_size = 1_000
  @geography = ''

  def geographies
    return ['Test-Geography'] if Rails.env.test?

    [
      # 'Oslo',
      'Norway',
    ]
  end

  def init
    puts 'Seeding the database... This might take a while.'
    execution_time = Benchmark.measure do
      seed(:monsters)
      seed(:items)
      seed(:trade_offers)
      seed(:portraits)
      geographies.each_with_index do |geography, index|
        puts "🌍 Seeding geography #{index + 1} of #{geographies.length} '#{geography}'..."
        @geography = geography
        seed(:real_world_locations)
        seed(:ley_lines)
        seed(:shops)
        seed(:dungeons)
      end
      puts "🙀 #{Spook.count} spooks in effect."
    end
    puts "Finished! (#{execution_time.real.round(2)}s)"
  end

  def seed(func)
    count = 0
    execution_time = Benchmark.measure do
      count = method(func).call
    end
    puts "🌱 Seeded #{count.to_fs(:delimited)} #{func.to_s.tr('_', ' ')} in #{execution_time.real.round(2)} seconds."
  end

  def real_world_locations
    locations = []
    filename = "#{@geography}.csv"
    csv_text = Rails.root.join('lib', 'seeds', filename).read
    csv = CSV.parse(csv_text, headers: true, encoding: 'UTF-8')
    csv.each do |row|
      lat, lon = row['coordinates'].split
      location = RealWorldLocation.new(
        ext_id: row['ext_id'],
        type: 'unassigned',
        coordinates: "POINT(#{lon} #{lat})",
        tags: parse_tags(row['tags']),
        source_file: filename,
      )

      percentile = location.ext_id[-2..].to_i
      location.type = 'shop' if percentile.in? 0..10
      location.type = 'ley-line' if percentile.in? 11..15

      # Enforce minimum distance between locations
      _, distance = location.nearest_real_world_location
      if distance.present? && distance <= 40.0
        location.destroy!
        puts "❌ Nixed OSM location ##{row['ext_id']} (#{lon} #{lat}), too close to other location" if ENV['verbose']
        next
      end

      locations << location
    end
    import(RealWorldLocation, locations, pre_validate: false, validate: false, skip_duplicates: true)
  end

  def monsters
    monsters = []
    csv_text = Rails.root.join('lib/seeds/monsters.csv').read
    csv = CSV.parse(csv_text, headers: true, encoding: 'UTF-8')
    csv.each do |row|
      monster = Monster.new
      monster.name = row['name']
      monster.description = row['description']
      monster.level = row['level']
      monster.classification = row['classification']
      # monster.tags = row['tags'].split(' ')
      monsters << monster
    end
    import(Monster, monsters)
  end

  def items
    items = []

    csv_text = Rails.root.join('lib/seeds/items.csv').read
    csv = CSV.parse(csv_text, headers: true, encoding: 'UTF-8')
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

      items << item
    end
    import(Item, items)
  end

  def trade_offers
    make_trade_offer_list = -> (list_name) {
      list = TradeOfferList.find_or_create_by(name: list_name)

      csv_text = Rails.root.join('lib/seeds/items.csv').read
      csv = CSV.parse(csv_text, headers: true, encoding: 'UTF-8')
      csv.each do |row|
        next unless row["#{list_name}_buy"] || row["#{list_name}_sell"]

        item = Item.find_by(name: row['name'])
        if item.nil?
          puts "⚠️  Item '#{row['name']}' not found when creating trade offer" if ENV['verbose']
          next
        end

        trade_offer = TradeOffer.new(item: item)
        trade_offer.buy_offer = row["#{list_name}_buy"]&.delete('^0-9') if row["#{list_name}_buy"].present?
        trade_offer.sell_offer = row["#{list_name}_sell"]&.delete('^0-9') if row["#{list_name}_sell"].present?
        if trade_offer.save
          list.trade_offers << trade_offer
        elsif ENV['verbose']
          puts "🛑 #{trade_offer.errors.inspect}"
        end
      end
      puts "🧾 #{list.trade_offers.length} trade offers in list '#{list_name}'."
    }

    %w[armorer jeweller magic_shop].each { |list_name| make_trade_offer_list.call(list_name) }
    TradeOffer.count
  end

  def portraits
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
    count = import(Portrait, portraits)

    # Post-import validation
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
    count
  end

  def shops
    magic_shop_offer_list = TradeOfferList.find_by(name: 'magic_shop')
    puts '⚠️ Error: magic_shop_offer_list should not be blank' and return 0 if magic_shop_offer_list.nil?

    jeweller_offer_list = TradeOfferList.find_by(name: 'jeweller')
    puts '⚠️ Error: jeweller_offer_list should not be blank' and return 0 if jeweller_offer_list.nil?

    armorer_offer_list = TradeOfferList.find_by(name: 'armorer')
    puts '⚠️ Error: armorer_offer_list should not be blank' and return 0 if armorer_offer_list.nil?

    npcs = []
    RealWorldLocation.where(type: 'shop').each do |rwl|
      random_digit = (Math.sqrt(rwl.ext_id.to_i) * 100).to_i.digits[0]
      npc = Npc.new({
                      role: 'shopkeeper',
                      real_world_location_id: rwl.id,
                      coordinates: rwl.coordinates,
                    })

      if random_digit.in? 0..2
        npc.shop_type = 'magic'
        npc.trade_offer_lists << magic_shop_offer_list
      elsif random_digit.in? 3..5
        npc.shop_type = 'jeweller'
        npc.trade_offer_lists << jeweller_offer_list
      else
        npc.shop_type = 'armorer'
        npc.trade_offer_lists << armorer_offer_list
      end

      # Avoid placing identical shops right next to each other
      _, distance = npc.nearest_similar_shop
      if distance.present? && distance <= 200.0
        npc.destroy!
        rwl.update!(type: 'unassigned')
        puts "❌ Nixed shop (#{npc.shop_type}) at location ##{rwl.id} (#{rwl.coordinates.lon} #{rwl.coordinates.lat}), too close to similar shop" if ENV['verbose']
        next
      end

      next if npc.save

      puts "🛑 #{npc.errors.inspect}" if ENV['verbose']
    end
    Npc.shopkeepers.count
  end

  def ley_lines
    ley_lines = []
    RealWorldLocation.where(type: 'ley-line').each do |rwl|
      ley_line = LeyLine.new({
                               real_world_location_id: rwl.id,
                               coordinates: rwl.coordinates,
                             })

      # Avoid placing ley lines right next to each other
      _, distance = ley_line.nearest_ley_line
      if distance.present? && distance <= 850.0
        ley_line.destroy!
        rwl.update!(type: 'unassigned')
        puts "❌ Nixed ley line at location ##{rwl.id} (#{rwl.coordinates.lon} #{rwl.coordinates.lat}), too close to other ley line" if ENV['verbose']
        next
      end

      ley_lines << ley_line
    end
    import(LeyLine, ley_lines)
  end

  def dungeons
    dungeons = []
    locations = RealWorldLocation.for_dungeon.pluck(:id).shuffle
    Dungeon.min_dungeons.times do |counter|
      dungeon = Dungeon.new({
                              status: Dungeon.statuses[:active],
                              real_world_location_id: locations.pop,
                              created_at: counter.hours.ago,
                            })
      dungeons << dungeon
    end
    import(Dungeon, dungeons, pre_validate: true, validate: true)
  end

  private

  def import(model, data, pre_validate = true, validate = true, skip_duplicates = false)
    count_before_seeding = model.count
    data_to_import = []

    if pre_validate
      data.each do |o|
        if o.valid?
          data_to_import << o
        elsif ENV['verbose']
          puts "🛑 #{o.errors.inspect}"
        end
      end
    else
      data_to_import = data
    end

    model.import data_to_import, batch_size: @batch_size, validate: validate, on_duplicate_key_ignore: skip_duplicates
    model.count - count_before_seeding
  end

  def parse_tags(tags_str)
    tags_str.split(';').map do |tag|
      key, value = tag.split(':')
      { key => value }
    end.reduce({}, :merge)
  end
end

seed_helper = SeedHelper.new
seed_helper.init
