# frozen_string_literal: true

class LootContainer
  attr_reader :gold, :items, :empty

  def initialize
    @empty = true
    @gold = 0
    @items = []
  end

  def empty?
    @empty
  end

  def add_gold(amount)
    @gold += amount
    @empty = false if amount.positive?
  end

  def add_item(item)
    return if item.nil?

    rand(1..item.drop_max_amount).times { @items << item }
    @empty = false
  end

  def merge(other_inventory)
    @gold += other_inventory.gold
    @items.concat(other_inventory.items)
    @empty = false if @gold.positive? || @items.length.positive?
  end

  def grant_to(user, transaction_description)
    @transaction = InventoryTransaction.new(description: transaction_description)
    @transaction.order_add_gold(@gold, user.inventory) if @gold.positive?
    @items.each do |item|
      @transaction.order_create_item(item, user.inventory)
    end
    @transaction.save_and_apply!
  end
end
