# frozen_string_literal: true

class Api::V1::RunestonesController < Api::V1::ApiController
  before_action :find_runestone, only: %i[show]
  before_action :location_inspected, only: %i[show]

  def show
    render json: @runestone, status: :ok, serializer: RunestoneSerializer
  end

  def add_to_journal
    unless @current_user.has_discovered_runestone @runestone.id

    end

    render status: :ok
  end

  private

  def find_runestone
    runestone_id = params[:action] == 'show' ? params[:id] : params[:runestone_id]
    @runestone = Runestone.find(runestone_id)
    render status: :not_found if @runestone.nil?
  end

  def location_inspected
    @runestone.real_world_location.inspected!
  end
end
