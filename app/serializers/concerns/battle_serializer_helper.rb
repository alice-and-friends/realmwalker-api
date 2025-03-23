# frozen_string_literal: true

module BattleSerializerHelper
  extend ActiveSupport::Concern

  def battle_participant_json(participant)
    {
      name: participant.name,
      is_a_player: participant.is_a?(User),
      is_current_user: participant == current_user,
      type: participant.class.name,
      id: participant.id,
    }
  end

  def current_user
    @current_user ||= begin
      user = instance_options[:user]
      raise 'current_user is not a User object' unless user.is_a?(User)

      user
    end
  end
end
