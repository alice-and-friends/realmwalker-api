# frozen_string_literal: true

class Api::V1::InventoryItemsController < Api::V1::ApiController
  before_action :find_item

  # PATCH /api/v1/inventory_items/1
  def update
    if @inventory_item.update(inventory_item_params)
      render json: @inventory_item
    else
      render json: @inventory_item.errors, status: :unprocessable_entity
    end
  end

  private

  def inventory_item_params
    params.require(:inventory_item).permit(:id, :is_equipped, :inventory_id)
  end

  def find_item
    @inventory_item = InventoryItem.find(params[:id])
    render json: { error: 'Item not found' }, status: :not_found if @inventory_item.nil?
    render json: { error: 'You are not the owner' }, status: :forbidden unless belongs_to_current_user
  end

  def belongs_to_current_user
    # puts 'belongs to', @inventory_item.owner.inspect
    # puts 'touched by', @current_user.inspect
    @inventory_item.owner == @current_user
  end
end
