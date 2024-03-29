# frozen_string_literal: true

class Event < ApplicationRecord
  validate :must_finish_after_start

  # Scope for events that have started but not finished
  scope :active, -> { where('start_at <= ? AND finish_at >= ?', Time.current, Time.current) }

  # Scope for events that will start in the next 24 hours
  scope :upcoming, -> { where('start_at > ? AND start_at <= ?', Time.current, 24.hours.from_now) }

  def active?
    return false if start_at.nil?

    start_at <= Time.current && (finish_at.nil? || finish_at >= Time.current)
  end

  private

  def must_finish_after_start
    return if start_at.blank? || finish_at.blank?

    errors.add(:finish_at, 'must be after start time') if finish_at <= start_at
  end
end
