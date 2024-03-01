# frozen_string_literal: true

class Api::V1::BaseController < Api::V1::ApiController
  before_action :find_base, only: %i[show upgrade]

  def show
    render json: @base, status: :ok, serializer: BaseSerializer
  end

  def create
    render status: :internal_server_error and return if @current_user.nil?

    if @current_user.base.present?
      render status: :forbidden, json: { error: `User #{@current_user.player_tag} already owns a structure` } and return
    end

    @base = @current_user.construct_base_at(@current_user_geolocation[:point])

    render status: :internal_server_error and return if @base&.created_at.blank?

    render json: @base, status: :created, serializer: BaseSerializer
  end

  def upgrade
    render status: :internal_server_error and return if @current_user.nil?

    render status: :not_implemented

    # Make sure the user has enough money
    # render status: :payment_required if @current_user.gold < @trade_offer.sell_offer
  end

  private

  def find_base
    # render status: :internal_server_error, json: { error: 'Missing base_id parameter' } and return if params[:base_id].blank?

    @base = Base.find_by(owner: @current_user)
    render status: :not_found if @base.nil?
  end
end
