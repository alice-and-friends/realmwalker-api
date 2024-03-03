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
    directory = Rails.root.join('lib/seeds/geographies')
    if ENV['geographies'] == 'all'
      all_files = Dir.glob("#{directory}/*[!_]*.csv")
      geographies = all_files.map do |file|
        File.basename(file, '.csv') # This removes the .csv extension directly
      end
      geographies_string = geographies.join(', ')
      puts "geographies=#{geographies_string}"
      return geographies_string
    elsif ENV['geographies']
      geographies = ENV['geographies'].split(',').map(&:strip)
      geographies.each do |geography|
        Throw "Unknown geography '#{geography}'" unless directory.join("#{geography}.csv").exist?
      end
      return geographies
    end
    []
  end

  def init
    unless ENV['globals'] || ENV['geographies']
      puts "INFO: db:seed requires at least one parameter to run. Available parameters are:
  globals=yes # Seeds non-geographical data such as monsters, items, etc
  geographies=Sweden,Norway # Instructs which geographies to seed locations for"
      exit
    end

    puts 'Seeding the database... This might take a while.'
    execution_time = Benchmark.measure do
      if ENV['globals']
        seed(:monsters)
        seed(:items)
        seed(:trade_offers)
        seed(:portraits)
      end
      if ENV['geographies']
        geographies.each_with_index do |geography, index|
          puts "🌍 Seeding geography #{index + 1} of #{geographies.length} '#{geography}'..."
          @geography = geography
          seed(:real_world_locations)
          seed(:ley_lines)
          seed(:shops)
          seed(:dungeons)
          seed(:runestones)
        end
        puts "🙀 #{Spook.count} spooks in effect."
      end
    end
    puts "Finished! (#{execution_time.real.round(2).to_fs(:delimited)}s)"
  end

  def seed(func)
    count = 0
    execution_time = Benchmark.measure do
      count = method(func).call
    end
    puts "🌱 Seeded #{count.to_fs(:delimited)} #{func.to_s.tr('_', ' ')} in #{execution_time.real.round(2).to_fs(:delimited)} seconds."
  end

  def real_world_locations
    locations = []
    filename = "#{@geography}.csv"
    csv_text = Rails.root.join('lib', 'seeds', 'geographies', filename).read
    csv = CSV.parse(csv_text, headers: true, encoding: 'UTF-8')
    csv.each do |row|
      latitude, longitude = row['coordinates'].split
      location = RealWorldLocation.find_or_initialize_by(ext_id: row['ext_id'])
      location.assign_attributes(
        type: RealWorldLocation.types[:unassigned],
        coordinates: "POINT(#{longitude} #{latitude})",
        latitude: latitude,
        longitude: longitude,
        tags: parse_tags(row['tags']),
        source_file: filename,
        region: @geography,
      )

      percentile = location.deterministic_rand(1..100)
      location.type = RealWorldLocation.types[:ley_line] if percentile.in? 1..7
      location.type = RealWorldLocation.types[:shop] if percentile.in? 10..20
      location.type = RealWorldLocation.types[:runestone] if percentile == 100

      locations << location
    end
    import(RealWorldLocation, locations, bulk: false)

    # TODO: Delete any locations that are not in the geography file
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
      item.dropped_by_classifications = row['dropped_by_classifications']&.split(', ')
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
    RealWorldLocation.available.for_shop.where(region: @geography).find_each do |rwl|
      random_digit = rwl.deterministic_rand(100)
      npc = Npc.new({
                      role: 'shopkeeper',
                      real_world_location_id: rwl.id,
                      coordinates: rwl.coordinates,
                    })

      if random_digit.in? 1..30
        npc.shop_type = 'magic'
        npc.trade_offer_lists << magic_shop_offer_list
      elsif random_digit.in? 31..60
        npc.shop_type = 'jeweller'
        npc.trade_offer_lists << jeweller_offer_list
      else
        npc.shop_type = 'armorer'
        npc.trade_offer_lists << armorer_offer_list
      end

      npcs << npc if npc.valid?
    end
    import(Npc, npcs, bulk: false, recycle_locations: 'shop')
  end

  def ley_lines
    ley_lines = []
    RealWorldLocation.available.for_ley_line.where(region: @geography).find_each do |rwl|
      ley_line = LeyLine.new({
                               real_world_location_id: rwl.id,
                               coordinates: rwl.coordinates,
                             })
      ley_lines << ley_line
    end
    import(LeyLine, ley_lines, bulk: false, recycle_locations: 'ley_line')
  end

  def dungeons
    dungeons = []
    locations = RealWorldLocation.available.for_dungeon.where(region: @geography).pluck(:id).shuffle
    dungeon_target_count = 10 # Dungeon.min_active_dungeons(@geography)
    dungeon_target_count.times do |counter|
      dungeon = Dungeon.new(
        status: Dungeon.statuses[:active],
        real_world_location_id: locations.pop,
        created_at: (counter.hours + rand(0..59).minutes).ago,
      )
      dungeons << dungeon
    end
    import(Dungeon, dungeons, pre_validate: false, validate: true)
  end

  def runestones
    runestones = []
    templates = RunestonesHelper.all

    RealWorldLocation.available.for_runestone.where(region: @geography).find_each do |rwl|
      random_index = rwl.deterministic_rand(templates.length)
      template = templates[random_index]

      runestone = Runestone.new({
                                  name: template.name,
                                  runestone_id: template.id,
                                  real_world_location_id: rwl.id,
                                })
      runestones << runestone
    end
    import(Runestone, runestones, pre_validate: false, validate: true)
  end

  private

  # Split into two (bulk- and non-bulk) import methods?
  def import(model, data, bulk: true, pre_validate: true, validate: true, skip_duplicates: false, recycle_locations: '')
    count_before_seeding = model.count
    discarded_locations = []

    if bulk
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
      model.import(data_to_import, batch_size: @batch_size, validate: validate, on_duplicate_key_ignore: skip_duplicates)
    else
      data.each do |o|
        if o.valid?
          o.save!
          next
        end
        if recycle_locations != '' && o.errors[:coordinates]
          discarded_locations << o.real_world_location_id
          next
        end
        puts "🛑 #{o.errors.inspect}" if ENV['verbose']
      end
      unless discarded_locations.empty?
        RealWorldLocation.where(id: discarded_locations).update!(type: RealWorldLocation.types[:unassigned])
        puts "♻️  Recycled #{discarded_locations.size} real world locations ('#{recycle_locations}'=>'#{RealWorldLocation.types[:unassigned]}')" if ENV['verbose']
      end
    end

    model.count - count_before_seeding
  end

  def parse_tags(tags_str)
    tags_str.split(';').map do |tag|
      key, value = tag.split(':')
      { key => value }
    end.reduce({}, :merge)
  end
end

# Test config
if Rails.env.test?
  ENV['globals'] = 'yes'
  ENV['geographies'] = '_Test-Geography'
end

# Execute
seed_helper = SeedHelper.new
seed_helper.init
