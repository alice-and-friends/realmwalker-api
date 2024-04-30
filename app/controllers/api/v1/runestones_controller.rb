# frozen_string_literal: true

class Api::V1::RunestonesController < Api::V1::ApiController
  before_action :find_runestone
  before_action :location_inspected, only: %i[show]
  before_action :location_interacted, only: %i[add_to_journal]

  def show
    render json: @location, serializer: RunestoneSerializer, user: @current_user, seen_from: @current_user_geolocation
  end

  def add_to_journal
    @current_user.discover_runestone(@runestone.id)
    show
  end

  private

  def find_runestone
    location_id = params[:action] == 'show' ? params[:id] : params[:runestone_id]
    @location = RealmLocation.find_by(id: location_id)
    render status: :not_found and return unless @location

    @runestone = RunestonesHelper.find(@location.runestone_id)
    render status: :internal_server_error and return unless @runestone
  end

  def location_inspected
    @location.real_world_location.inspected!
  end

  def location_interacted
    @location.real_world_location.interacted!
  end
end
