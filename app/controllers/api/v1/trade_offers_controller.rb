# frozen_string_literal: true

class Api::V1::TradeOffersController < Api::V1::ApiController
  before_action :find_npc
  before_action :find_trade_offer, only: %i[buy sell]
  before_action :location_interacted, only: %i[buy sell]

  def buy
    render status: :internal_server_error and return if @current_user.nil?

    # Make sure the user has enough money
    render status: :payment_required and return if @current_user.gold < @trade_offer.sell_offer

    # Conduct transaction
    @current_user.gains_or_loses_gold(-@trade_offer.sell_offer)
    @current_user.gain_item @trade_offer.item
    render json: {
      inventory: {
        gold: @current_user.gold,
        items: ActiveModelSerializers::SerializableResource.new(@current_user.inventory_items.alphabetical, each_serializer: InventoryItemSerializer)
      }
    }, status: :ok
  end

  def sell
    render status: :internal_server_error and return if @current_user.nil?

    # Make sure the user has the item
    inventory_item = @current_user.inventory_items.find_by(item_id: @trade_offer.item_id)
    render status: :not_found, json: { error: 'User does not have the required item(s)' } and return if inventory_item.nil?

    # Conduct transaction
    @current_user.lose_item @trade_offer.item
    @current_user.gains_or_loses_gold(@trade_offer.buy_offer)
    render json: {
      inventory: {
        gold: @current_user.gold,
        items: ActiveModelSerializers::SerializableResource.new(@current_user.inventory_items.alphabetical, each_serializer: InventoryItemSerializer, user: @current_user)
      }
    }, status: :ok
  end

  private

  def location_interacted
    @npc.real_world_location.interacted!
  end

  def find_npc
    render status: :internal_server_error, json: { error: 'Missing npc_id parameter' } and return if params[:npc_id].blank?

    @npc = Npc.find(params[:npc_id])
    render status: :not_found if @npc.nil?
  end

  def find_trade_offer
    render status: :internal_server_error, json: { error: 'Missing trade_offer_id parameter' } and return if params[:trade_offer_id].blank?

    @trade_offer = @npc.trade_offers.find(params[:trade_offer_id])
    render status: :not_found and return if @trade_offer.nil?

    render status: :internal_server_error and nil if @trade_offer.item.nil?
  end
end
