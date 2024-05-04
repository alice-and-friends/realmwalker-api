# frozen_string_literal: true

class MiniQuest < ApplicationRecord
  self.inheritance_column = nil
  belongs_to :user, dependent: :destroy
  belongs_to :item, dependent: :destroy
  belongs_to :quest_giver, class_name: 'Npc', dependent: :destroy

  alias_attribute :quest_giver, :given_by

  enum type: {
    fetch: 'fetch',
    deliver: 'deliver',
  }

  enum status: {
    offered: 'offered',
    started: 'started',
    expired: 'expired',
  }

  before_validation :randomize, on: :create

  private

  def randomize
    self.type = types.values.sample
  end

  def random_item
    item_table = Item.where(mini_quests: true)
    raise 'No suitable items for mini quests' if item_table.empty?

    self.item = item if item.nil?
    self.item_amount = 1 if item_amount.nil?
  end
end
