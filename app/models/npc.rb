# frozen_string_literal: true

class Npc < RealmLocation
  enum roles: { shopkeeper: 0 }
  enum shop_types: { armorer: 0, jeweller: 1, magic: 3 }

  validates :role, inclusion: { in: roles.keys }
  validates :shop_type, inclusion: { in: shop_types.keys << nil }
  before_validation :set_real_world_location, on: :create
  before_validation :random_name!, on: :create

  after_create do |npc|
    Rails.logger.debug "📌 Spawned a new NPC, say hello to #{npc.name}. There are now #{Npc.count} NPCs."
  end
  after_destroy do |npc|
    Rails.logger.debug "❌ Destroyed NPC #{npc.name}. There are now #{Npc.count} NPCs."
  end

  private

  def set_real_world_location
    return if real_world_location_id.present?

    self.real_world_location = RealWorldLocation
                               .for_npc
                               .where.not(id: [RealmLocation.real_world_location_ids_currently_in_use])
                               .sample
  end

  def random_name!
    self.name = Faker::Name.first_name
  end
end
