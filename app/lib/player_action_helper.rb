# frozen_string_literal: true

class PlayerActionHelper
  def self.for_player(player)
    new(player).available_actions
  end

  def initialize(player)
    @player = player
  end

  def available_actions
    action_ids = gather_action_ids
    PlayerActionRegistry.resolve_all(action_ids)
  end

  private

  def gather_action_ids
    ids = []

    ids.concat PlayerActionRegistry.universal.pluck(:id)
    ids.concat collect_action_ids_from(@player.equipped_items)
    ids.concat collect_action_ids_from(@player.consumable_items)

    ids.uniq
  end

  def collect_action_ids_from(inventory_items)
    return [] unless inventory_items

    inventory_items.flat_map do |inventory_item|
      inventory_item.item&.actions || []
    end
  end
end
