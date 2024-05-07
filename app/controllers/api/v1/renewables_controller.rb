# frozen_string_literal: true

class Api::V1::RenewablesController < Api::V1::ApiController
  before_action :find_location
  before_action :location_inspected, only: %i[show]
  before_action :location_interacted, only: %i[collect_all]

  def show
    render json: @location, serializer: RealmLocationSerializer, seen_from: @current_user_geolocation
  end

  def collect_all
    show
  end

  private

  def find_location
    location_id = params[:action] == 'show' ? params[:id] : params[:renewable_id]
    @location = RealmLocation.find_by(id: location_id)
    render status: :not_found and return unless @location
  end

  def location_inspected
    @location.real_world_location.inspected!
  end

  def location_interacted
    @location.real_world_location.interacted!
  end
end
