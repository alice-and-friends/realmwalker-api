# frozen_string_literal: true

class LocationRelevanceWorker
  include Sidekiq::Job
  sidekiq_options queue: 'slow'

  def perform(location_ids, grade)
    throw('location_ids is blank. Do not call this worker without at least one id') if location_ids.blank?
    throw("#{grade} is not a valid relevance grade") unless grade.in? RealWorldLocation.relevance_grades.values

    # NB: Due to use of update_all, the updated_at timestamp will not be updated
    RealWorldLocation.where(id: location_ids).where('relevance_grade < ?', grade).update_all(relevance_grade: grade)
  end
end
