# frozen_string_literal: true

class Npc < RealmLocation
  include Species
  include Gender

  ROLES = %w[shopkeeper castle].freeze
  SHOP_TYPES = %w[armorer jeweller magic castle].freeze

  belongs_to :portrait
  has_and_belongs_to_many :trade_offer_lists, join_table: 'npcs_trade_offer_lists'
  has_many :trade_offers, through: :trade_offer_lists
  has_many :spooks, dependent: :destroy
  has_many :dungeons, through: :spooks

  validates :species, inclusion: { in: Species::SPECIES }
  validates :gender, inclusion: { in: Gender::GENDERS }
  validates :role, presence: true, inclusion: { in: ROLES }
  validates :shop_type, inclusion: { in: SHOP_TYPES }
  validate :must_have_shop_type, if: :shop?
  validate :must_have_trade_offer_list, if: :shop?
  validate :must_obey_minimum_distance, if: :shop?

  before_validation :set_real_world_location!, on: :create
  before_validation :set_region_and_coordinates!, on: :create
  before_validation :assign_species!, on: :create
  before_validation :assign_gender!, on: :create
  before_validation :assign_name!, on: :create
  before_validation :assign_portrait!, on: :create
  before_validation :assign_trade_offers!, on: :create, if: :shop?

  after_create do |npc|
    Rails.logger.debug "📌 Spawned a new NPC, say hello to #{npc.name}. There are now #{Npc.count} NPCs."
  end
  after_destroy do |npc|
    Rails.logger.debug "❌ Destroyed NPC #{npc.name}. There are now #{Npc.count} NPCs."
  end

  scope :shopkeepers, -> { where(role: 'shopkeeper') }
  scope :with_spook_status, lambda {
    left_outer_joins(:spooks)
      .select('realm_locations.*, COUNT(spooks.id) > 0 AS spooked')
      .group('realm_locations.id')
  }

  def shop?
    role == 'shopkeeper' || shop_type.present?
  end

  def trade_offer_ids
    trade_offer_lists.flat_map(&:trade_offer_ids).uniq
  end

  def buy_offers(for_user = nil)
    offers = TradeOffer
             .where('trade_offers.buy_offer IS NOT NULL AND trade_offers.id IN (?)', trade_offer_ids)
             .joins(item: :trade_offers)
             .includes(item: :trade_offers) # Eager load associated records
             .distinct
             .sort_by { |offer| offer.item.name }

    if for_user.present?
      # Filter out items the user doesn't have
      # return offers.select { |offer| for_user.inventory_count_by_item_id(offer.item_id).positive? }

      # Sort the items that the user have in their inventory at the top
      return offers.sort_by { |offer| for_user.inventory_count_by_item_id(offer.item_id).positive? ? 0 : 1 }
    end

    offers
  end

  def sell_offers
    TradeOffer
      .where('trade_offers.sell_offer IS NOT NULL AND trade_offers.id IN (?)', trade_offer_ids)
      .joins(item: :trade_offers)
      .includes(item: :trade_offers) # Eager load associated records
      .distinct
      .sort_by { |offer| offer.item.name }
  end

  def spooked?
    # This optimization shortcut works when using the "with_spook_status" scope
    return spooked if respond_to?(:spooked)

    # Fallback solution is to join the spooks table
    spooks.any?
  end

  private

  def set_real_world_location!
    self.real_world_location = RealWorldLocation.available.first if real_world_location_id.nil?
  end

  def assign_species!
    return if species.present?

    # Define the species probabilities for the castle role and default role
    species_probabilities_castle = [
      ['human', 80], # 65%
      ['dwarf', 15], # 10%
      ['kenku', 5],  # 5%
    ]
    species_probabilities_default = [
      ['human', 64], # 64%
      ['elf', 10],   # 10%
      ['giant', 5],  # 5%
      ['dwarf', 5],  # 5%
      ['troll', 5],  # 5%
      ['goblin', 5], # 5%
      ['kenku', 5],  # 5%
      ['djinn', 1],  # 1%
    ]

    # Assign the appropriate species probabilities array based on the role
    selected_probabilities = role == 'castle' ? species_probabilities_castle : species_probabilities_default

    # Validate total probabilities add up to 100
    total_probability = selected_probabilities.sum { |_, probability| probability }
    raise "Total probabilities do not add up to 100, actual total is #{total_probability}" unless total_probability == 100

    # Convert probabilities to cumulative ranges for selection
    cumulative = 0
    species_ranges = selected_probabilities.each_with_object({}) do |(species, probability), ranges|
      range_start = cumulative + 1
      cumulative += probability
      ranges[range_start..cumulative] = species
    end

    # Generate a random number and assign species based on the cumulative ranges
    r = rand(1..100)
    self.species = species_ranges.find { |range, _| range === r }.last
  end

  def assign_gender!
    return if gender.present?

    self.gender = 'm' and return if species == 'djinn' # All djinn are male

    r = rand(0..10)
    self.gender = if r.zero?
                    'x'
                  elsif r.even?
                    'f'
                  else
                    'm'
                  end
  end

  def assign_name!
    return if name.present?

    method_name = case species
                  when 'human', 'elf', 'dwarf', 'djinn', 'goblin'
                    "#{species}_#{gender == 'm' ? 'male' : gender == 'f' ? 'female' : 'neutral'}_name"
                  when 'giant', 'troll', 'kenku'
                    "humanoid_#{gender == 'm' ? 'male' : gender == 'f' ? 'female' : 'neutral'}_name"
                  end
    raise 'no method name' if method_name.nil?

    self.name = Faker::Name.send(method_name)
  end

  def assign_portrait!
    self.portrait = Portrait.where(':species = ANY(species) AND :gender = ANY(genders) and :group = ANY(groups)',
                                species: species, gender: gender, group: shop_type).sample
  end

  def assign_trade_offers!
    # SHOP TYPE
    shop_type_trade_offer_list = TradeOfferList.find_by(name: shop_type)
    if shop_type_trade_offer_list.nil?
      Rails.logger.warn "Could not find trade offer list for shop_type '#{shop_type}'"
      return
    end
    trade_offer_lists << shop_type_trade_offer_list

    # SPECIES SPECIFIC
    case species
    when 'elf'
      elf_trade_offer_list = TradeOfferList.find_by(name: 'elf')
      return if elf_trade_offer_list.nil?

      trade_offer_lists << elf_trade_offer_list
    end
  end

  def must_have_shop_type
    errors.add(:role, 'shopkeeper requires a valid shop_type to be set') unless shop_type.in? SHOP_TYPES
  end

  def must_have_trade_offer_list
    errors.add(:role, 'shopkeeper role requires at least one trade offer list') if trade_offer_lists.empty?
  end

  # Avoid placing identical shops right next to each other
  def must_obey_minimum_distance
    throw('Coordinates blank') if coordinates.blank?

    min_distance = if shop_type == 'castle'
                     2_370.0 # Measured distance between Akershus Festning and Oscarshall
                   else
                     200.0
                   end

    point = "ST_GeographyFromText('POINT(#{coordinates.longitude} #{coordinates.latitude})')"
    distance_query = Arel.sql("ST_Distance(coordinates::geography, #{point}) <= #{min_distance}")

    exists_query = Npc.where(region: region, shop_type: shop_type)
                      .where.not(id: id)
                      .where(distance_query)
                      .exists?

    errors.add(:coordinates, 'Too close to similar npc') if exists_query
  end
end
