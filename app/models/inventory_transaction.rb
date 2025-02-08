# frozen_string_literal: true

class InventoryTransaction < ApplicationRecord
  ItemEntry = Struct.new(:inventory_item_id, :item_id, :name, :source_id, :destination_id, keyword_init: true)
  GoldEntry = Struct.new(:amount, :name, :source_id, :destination_id, keyword_init: true)

  enum status: { staged: 'staged', completed: 'completed', failed: 'failed' }

  validates :description, presence: true # Aids in debugging failed transactions

  serialize :create_items, Array
  serialize :transfer_items, Array
  serialize :destroy_items, Array
  serialize :add_gold, Array
  serialize :transfer_gold, Array
  serialize :subtract_gold, Array

  # === ORDER METHODS ===

  def order_create_item(item, inventory)
    raise 'Not an item' unless item.is_a?(Item)
    raise 'Not an inventory' unless inventory.is_a?(Inventory)

    create_items << ItemEntry.new(
      item_id: item.id,
      name: item.name,
      destination_id: inventory.id,
    ).to_h
  end

  def order_transfer_item(inventory_item, destination_inventory)
    raise 'Not an inventory item' unless inventory_item.is_a?(InventoryItem)
    raise 'Not an inventory' unless destination_inventory.is_a?(Inventory)

    transfer_items << ItemEntry.new(
      inventory_item_id: inventory_item.id,
      item_id: inventory_item.item_id,
      name: inventory_item.item.name,
      source_id: inventory_item.inventory_id,
      destination_id: destination_inventory.id,
    ).to_h
  end

  def order_destroy_item(inventory_item)
    raise 'Not an inventory item' unless inventory_item.is_a?(InventoryItem)

    destroy_items << ItemEntry.new(
      inventory_item_id: inventory_item.id,
      item_id: inventory_item.item_id,
      name: inventory_item.item.name,
      source_id: inventory_item.inventory_id,
    ).to_h
  end

  def order_add_gold(amount, destination_inventory)
    raise 'Must be positive amount' unless amount.positive?
    raise 'Not an inventory' unless destination_inventory.is_a?(Inventory)

    add_gold << GoldEntry.new(
      amount: amount,
      name: 'Gold',
      destination_id: destination_inventory.id,
    ).to_h
  end

  def order_transfer_gold(amount, source_inventory, destination_inventory)
    raise 'Must be positive amount' unless amount.positive?
    raise 'Not an inventory' unless source_inventory.is_a?(Inventory)
    raise 'Not an inventory' unless destination_inventory.is_a?(Inventory)

    transfer_gold << GoldEntry.new(
      amount: amount,
      name: 'Gold',
      source_id: source_inventory.id,
      destination_id: destination_inventory.id,
    ).to_h
  end

  def order_subtract_gold(amount, source_inventory)
    raise 'Must be positive amount' unless amount.positive?
    raise 'Not an inventory' unless source_inventory.is_a?(Inventory)

    subtract_gold << GoldEntry.new(
      amount: amount,
      name: 'Gold',
      source_id: source_inventory.id,
    ).to_h
  end

  # === APPLY TRANSACTION ===

  def save_and_apply!
    raise "InventoryTransaction #{id} aborted: The transaction has already been completed." if completed?
    raise "InventoryTransaction #{id} aborted: The transaction is not valid." unless valid?

    if id.nil? || changed?
      raise "InventoryTransaction #{id} aborted: Unable to save the transaction." unless save
    end

    begin
      ActiveRecord::Base.transaction do
        process_create_items
        process_transfer_items
        process_destroy_items
        process_add_gold
        process_transfer_gold
        process_subtract_gold
        completed!
      end
      true
    rescue StandardError => e
      failed!
      Rails.logger.error("InventoryTransaction #{id} failed: #{e.message}")
      false
    end
  end

  private

  def create_item=(value)
    raise 'Direct modification of add_item is not allowed, use order_create_item'
  end

  def transfer_item=(value)
    raise 'Direct modification of transfer_item is not allowed, use order_transfer_item'
  end

  def destroy_item=(value)
    raise 'Direct modification of subtract_item is not allowed, use order_destroy_item'
  end

  def add_gold=(value)
    raise 'Direct modification of add_gold is not allowed, use order_add_gold'
  end

  def transfer_gold=(value)
    raise 'Direct modification of transfer_gold is not allowed, use order_transfer_gold'
  end

  def subtract_gold=(value)
    raise 'Direct modification of subtract_gold is not allowed, use order_subtract_gold'
  end

  # === ITEM PROCESSING ===

  def process_create_items
    create_items.each do |entry|
      inventory = Inventory.find_by(id: entry[:destination_id])
      raise ActiveRecord::RecordNotFound, "Destination inventory #{entry[:destination_id]} not found" unless inventory

      inventory_item = InventoryItem.create!(item_id: entry[:item_id], inventory_id: inventory.id)
      entry[:inventory_item_id] = inventory_item.id
    end
    update!(create_items: create_items)
  end

  def process_transfer_items
    transfer_items.each do |entry|
      source_inventory = Inventory.find_by(id: entry[:source_id])
      destination_inventory = Inventory.find_by(id: entry[:destination_id])
      item = InventoryItem.find_by(id: entry[:inventory_item_id], inventory_id: entry[:source_id])

      raise ActiveRecord::RecordNotFound, "Source inventory #{entry[:source_id]} not found" unless source_inventory
      raise ActiveRecord::RecordNotFound, "Destination inventory #{entry[:destination_id]} not found" unless destination_inventory
      raise ActiveRecord::RecordNotFound, "Inventory item #{entry[:inventory_item_id]} not found in source inventory" unless item

      item.update!(inventory_id: destination_inventory.id)
    end
  end

  def process_destroy_items
    destroy_items.each do |entry|
      inventory = Inventory.find_by(id: entry[:source_id])
      item = InventoryItem.find_by(id: entry[:inventory_item_id], inventory_id: entry[:source_id])

      raise ActiveRecord::RecordNotFound, "Source inventory #{entry[:source_id]} not found" unless inventory
      raise ActiveRecord::RecordNotFound, "Inventory item #{entry[:inventory_item_id]} not found in source inventory" unless item

      item.destroy!
    end
  end

  # === GOLD PROCESSING ===

  def process_add_gold
    add_gold.each do |entry|
      inventory = Inventory.find_by(id: entry[:destination_id])
      raise ActiveRecord::RecordNotFound, "Destination inventory #{entry[:destination_id]} not found" unless inventory

      inventory.gold += entry[:amount]
      inventory.save!
    end
  end

  def process_transfer_gold
    transfer_gold.each do |entry|
      source_inventory = Inventory.find_by(id: entry[:source_id])
      raise ActiveRecord::RecordNotFound, "Source inventory #{entry[:source_id]} not found" unless source_inventory
      raise StandardError, 'Insufficient gold in source inventory' if source_inventory.gold < entry[:amount]

      destination_inventory = Inventory.find_by(id: entry[:destination_id])
      raise ActiveRecord::RecordNotFound, "Destination inventory #{entry[:destination_id]} not found" unless destination_inventory

      source_inventory.gold -= entry[:amount]
      source_inventory.save!
      destination_inventory.gold += entry[:amount]
      destination_inventory.save!
    end
  end

  def process_subtract_gold
    subtract_gold.each do |entry|
      inventory = Inventory.find_by(id: entry[:source_id])
      raise ActiveRecord::RecordNotFound, "Source inventory #{entry[:source_id]} not found" unless inventory
      raise StandardError, 'Insufficient gold in source inventory' if inventory.gold < entry[:amount]

      inventory.gold -= entry[:amount]
      inventory.save!
    end
  end
end
