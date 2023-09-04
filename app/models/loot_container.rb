# frozen_string_literal: true

class LootContainer
  attr_reader :gold, :items

  def initialize
    @gold = 0
    @items = []
  end

  def add_gold(amount)
    @gold += amount
  end

  def add_item(item)
    rand(1..item.drop_max_amount).times { @items << item } unless item.nil?
  end

  def merge(other_inventory)
    @gold += other_inventory.gold
    @items.concat(other_inventory.items)
  end
end
