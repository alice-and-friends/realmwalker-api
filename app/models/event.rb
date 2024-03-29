# frozen_string_literal: true

class Event < ApplicationRecord
  # Scope for events that have started but not finished
  scope :active, -> { where('start_at <= ? AND finish_at >= ?', Time.current, Time.current) }

  # Scope for events that will start in the next 24 hours
  scope :upcoming, -> { where('start_at > ? AND start_at <= ?', Time.current, 24.hours.from_now) }

  def active?
    start_at <= Time.current && (finish_at.nil? || finish_at >= Time.current)
  end
end
