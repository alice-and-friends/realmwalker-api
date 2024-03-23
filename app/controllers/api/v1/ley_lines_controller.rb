# frozen_string_literal: true

class Api::V1::LeyLinesController < Api::V1::ApiController
  before_action :find_ley_line
  before_action :location_inspected, only: %i[show]
  before_action :location_interacted, only: %i[capture]

  def show
    render json: @ley_line, serializer: LeyLineSerializer
  end

  def capture
    @ley_line.captured_by! @current_user
    render json: @ley_line, serializer: LeyLineSerializer
  end

  private

  def find_ley_line
    ley_line_id = params[:action] == 'show' ? params[:id] : params[:ley_line_id]
    @ley_line = LeyLine.find(ley_line_id)
    render status: :not_found if @ley_line.nil?
  end

  def location_inspected
    @ley_line.real_world_location.inspected!
  end

  def location_interacted
    @ley_line.real_world_location.interacted!
  end
end
