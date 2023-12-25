# frozen_string_literal: true

class Npc < RealmLocation
  include Species
  include Gender

  belongs_to :portrait
  has_and_belongs_to_many :trade_offer_lists, join_table: 'npcs_trade_offer_lists'
  has_many :trade_offers, through: :trade_offer_lists

  ROLES = %w[shopkeeper].freeze
  SHOP_TYPES = %w[armorer jeweller magic].freeze
  SPOOK_DISTANCE = 450 # meters
  before_validation :assign_species!, on: :create
  before_validation :assign_gender!, on: :create
  before_validation :assign_name!, on: :create
  before_validation :assign_portrait!, on: :create
  validates :species, inclusion: { in: Species::SPECIES }
  validates :gender, inclusion: { in: Gender::GENDERS }
  validates :role, presence: true, inclusion: { in: ROLES }
  validates :shop_type, inclusion: { in: SHOP_TYPES }
  validate :shopkeeper_has_shop_type, if: :shop?
  validate :shopkeeper_has_trade_offer_list, if: :shop?

  after_create do |npc|
    Rails.logger.debug "📌 Spawned a new NPC, say hello to #{npc.name}. There are now #{Npc.count} NPCs."
  end
  after_destroy do |npc|
    Rails.logger.debug "❌ Destroyed NPC #{npc.name}. There are now #{Npc.count} NPCs."
  end

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

  delegate :coordinates, to: :real_world_location

  # TODO: This generates a crazy amount of db queries. Use materialized view?
  def spooked
    Dungeon.active.joins(:real_world_location).where(
      "ST_DWithin(real_world_locations.coordinates::geography, :coordinates, #{SPOOK_DISTANCE})", coordinates: coordinates
    ).exists?
  end

  private

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
end
