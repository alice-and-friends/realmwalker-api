# frozen_string_literal: true

class Api::V1::InventoryController < Api::V1::ApiController
  before_action :find_inventory

  def show
    render json: @current_user_inventory, status: :ok, serializer: InventorySerializer
  end

  def set_equipped
    item = InventoryItem.find_by(id: params[:item_id])
    if item.nil?
      render json: { error: 'No such item' }, status: :not_found and return
    end

    if params[:equipped].to_s == 'true'
      equipped, unequip_items = @current_user.equip_item(item, force = params[:force].to_s == 'true')
      render json: {
        equipped: equipped,
        unequip_items: ActiveModelSerializers::SerializableResource.new(unequip_items, each_serializer: InventoryItemSerializer),
        inventory: ActiveModelSerializers::SerializableResource.new(@current_user_inventory, serializer: InventorySerializer),
      }
    else
      @current_user.unequip_item(item)
      render json: {
        equipped: false,
        unequip_items: ActiveModelSerializers::SerializableResource.new([item], each_serializer: InventoryItemSerializer),
        inventory: ActiveModelSerializers::SerializableResource.new(@current_user_inventory, serializer: InventorySerializer),
      }
    end
  end

  private

  def find_inventory
    @current_user_inventory = @current_user.inventory
  end
end
