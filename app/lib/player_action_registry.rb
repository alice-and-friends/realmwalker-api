# frozen_string_literal: true

module PlayerActionRegistry
  ACTIONS = [
    {
      id: 'flee',
      type: 'flee',
      label: 'Flee',
      scope: :universal,
    },
    {
      id: 'basic_attack',
      type: 'attack',
      label: 'Basic Attack',
      damageTypes: ['bludgeoning'],
      scope: :universal,
    },
    {
      id: 'slash',
      type: 'attack',
      label: 'Slash Attack',
      damageTypes: ['slashing'],
    },
    {
      id: 'use_healing_potion',
      type: 'use_item',
      label: 'Use Healing Potion',
      itemId: 'healing_potion',
    },
  ].freeze

  def self.actions
    ACTIONS
  end

  def self.validate!
    seen_ids = Set.new

    actions.each do |action|
      id = action[:id]
      raise 'Missing :id in action' unless id
      raise "Duplicate action id: #{id}" unless seen_ids.add?(id)

      raise "Missing or invalid label for action `#{id}`" unless action[:label].is_a?(String)
      raise "Invalid type for action `#{id}`" unless PlayerActionTypes.valid?(action[:type])

      next unless action[:type] == 'attack'

      raise "Missing damageTypes for attack `#{id}`" if action[:damageTypes].blank?

      action[:damageTypes].each do |type|
        raise "Invalid damage type `#{type}` in action `#{id}`" unless DamageTypes.valid?(type)
      end
    end
  end

  def self.find(action_id)
    actions.find { |a| a[:id] == action_id.to_s }
  end

  def self.resolve_all(action_ids)
    action_ids.uniq.filter_map do |id|
      action = find(id)
      Rails.logger.warn "[PlayerActionRegistry] Unknown action ID: #{id.inspect}" unless action
      action
    end
  end

  def self.universal
    actions.select { |a| a[:scope] == :universal }
  end
end
