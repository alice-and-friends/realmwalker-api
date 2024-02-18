# frozen_string_literal: true

class Npc < RealmLocation
  include Species
  include Gender

  ROLES = %w[shopkeeper].freeze
  SHOP_TYPES = %w[armorer jeweller magic].freeze

  belongs_to :portrait
  has_and_belongs_to_many :trade_offer_lists, join_table: 'npcs_trade_offer_lists'
  has_many :trade_offers, through: :trade_offer_lists
  has_many :spooks, dependent: :destroy
  has_many :dungeons, through: :spooks

  validates :species, inclusion: { in: Species::SPECIES }
  validates :gender, inclusion: { in: Gender::GENDERS }
  validates :role, presence: true, inclusion: { in: ROLES }
  validates :shop_type, inclusion: { in: SHOP_TYPES }
  validate :shopkeeper_has_shop_type, if: :shop?
  validate :shopkeeper_has_trade_offer_list, if: :shop?
  validate :minimum_distance, if: :shop?

  before_validation :set_real_world_location!, on: :create
  before_validation :set_region_and_coordinates!, on: :create
  before_validation :assign_species!, on: :create
  before_validation :assign_gender!, on: :create
  before_validation :assign_name!, on: :create
  before_validation :assign_portrait!, on: :create

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
    role == 'shopkeeper'
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
    self.real_world_location = RealWorldLocation.free.first if real_world_location_id.nil?
  end

  def assign_species!
    r = rand(1..100)
    self.species = if r.in? 1..10 # 10%
                     'elf'
                   elsif r.in? 11..15 # 5%
                     'giant'
                   elsif r.in? 16..20 # 5%
                     'dwarf'
                   elsif r.in? 21..25 # 5%
                     'troll'
                   elsif r.in? 26..30 # 5%
                     'goblin'
                   elsif r.in? 31..35 # 5%
                     'kenku'
                   else # 65%
                     'human'
                   end
  end

  def assign_gender!
    return if gender.present?

    r = rand(11)
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

    self.name = if gender == 'm'
                  Faker::Name.male_first_name
                elsif gender == 'f'
                  Faker::Name.female_first_name
                else
                  Faker::Name.neutral_first_name
                end
  end

  def assign_portrait!
    self.portrait = Portrait.where(':species = ANY(species) AND :gender = ANY(genders) and :group = ANY(groups)',
                                species: species, gender: gender, group: shop_type).sample
  end

  def shopkeeper_has_shop_type
    errors.add(:role, 'shopkeeper requires a valid shop_type to be set') unless shop_type.in? SHOP_TYPES
  end

  def shopkeeper_has_trade_offer_list
    errors.add(:role, 'shopkeeper role requires at least one trade offer list') if trade_offer_lists.empty?
  end

  # Avoid placing identical shops right next to each other
  def minimum_distance
    throw('Coordinates blank') if coordinates.blank?

    point = "ST_GeographyFromText('POINT(#{coordinates.lon} #{coordinates.lat})')"
    distance_query = Arel.sql("ST_Distance(coordinates::geography, #{point}) <= 200.0")

    exists_query = Npc.shopkeepers.where(region: region, shop_type: shop_type)
                      .where.not(id: id)
                      .where(distance_query)
                      .exists?

    errors.add(:coordinates, 'Too close to similar shop') if exists_query
  end
end
