# frozen_string_literal: true

class Api::V1::NpcsController < Api::V1::ApiController
  before_action :find_npc, only: [:show]
  before_action :location_inspected, only: [:show]

  def show
    render json: @npc, status: :ok, user: @current_user
  end

  private

  def find_npc
    @npc = Npc.find_by(id: params[:id])
    render json: { error: 'NPC not found' }, status: :not_found if @npc.nil?
  end

  def location_inspected
    @npc.real_world_location.inspected!
  end
end
