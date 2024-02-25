# frozen_string_literal: true

class Api::V1::JournalController < Api::V1::ApiController
  def runestones
    discovered_runestones = @current_user.discovered_runestones

    # Map discovered runestones to their full details
    discovered_details = discovered_runestones.map do |id|
      runestone = RunestonesHelper.find(id)
      { id: runestone.id, name: runestone.name, text: runestone.text }
    end

    total_runestones = RunestonesHelper.count
    undiscovered_count = total_runestones - discovered_runestones.count

    render json: {
      discovered_runestones: discovered_details,
      discovered_count: discovered_runestones.count,
      undiscovered_count: undiscovered_count,
    }
  end
end
