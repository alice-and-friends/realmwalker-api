# frozen_string_literal: true

class Event < ApplicationRecord
  FULL_MOON = {
    name: 'Full moon', # Must match database record
    days: 13..15,
  }.freeze

  validate :must_finish_after_start

  after_save :schedule_end_job

  # Scope for events that have started but not finished
  scope :active, -> { where('start_at <= ? AND finish_at >= ?', Time.current, Time.current) }

  # Scope for events that will start in the next 24 hours
  scope :upcoming, -> { where('start_at > ? AND start_at <= ?', Time.current, 24.hours.from_now) }

  # Checks if an event is currently active
  def active?
    return false if start_at.nil?

    start_at <= Time.current && (finish_at.nil? || finish_at >= Time.current)
  end

  # Checks if an event is scheduled to start in the future
  def upcoming?
    start_at.present? && start_at > Time.current
  end

  # Checks if an event is either active or upcoming
  def active_or_upcoming?
    active? || upcoming?
  end

  # Schedules a job to be executed when the event ends
  def schedule_end_job
    # Ensure finish_at is set and in the future before scheduling the job
    return unless finish_at.present? && finish_at > Time.current

    if name == FULL_MOON[:name]
      # Remove current jobs before scheduling a new one
      SidekiqHelper.clear_all_jobs_for_class('LycanthropeExpirationWorker')
      LycanthropeExpirationWorker.perform_at(finish_at)
    end
  end

  private

  def must_finish_after_start
    return if start_at.blank? || finish_at.blank?

    errors.add(:finish_at, 'must be after start time') if finish_at <= start_at
  end
end