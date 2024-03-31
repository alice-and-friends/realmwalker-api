# frozen_string_literal: true

class EventsScheduler
  include Sidekiq::Job

  def perform
    full_moon_schedule
  end

  def full_moon_schedule
    full_moon_event = Event.find_by(name: Event::FULL_MOON[:name])
    return unless full_moon_event

    today = Time.zone.today
    start_of_event = Date.new(today.year, today.month, Event::FULL_MOON[:days].first)
    end_of_event = Date.new(today.year, today.month, Event::FULL_MOON[:days].last).end_of_day

    # Adjust for next month if the current date is past this month's event period
    if today > end_of_event
      next_month = today.next_month
      start_of_event = Date.new(next_month.year, next_month.month, Event::FULL_MOON[:days].first)
      end_of_event = Date.new(next_month.year, next_month.month, Event::FULL_MOON[:days].last).end_of_day
    end

    # Use the new method to check if the event is active or upcoming
    return if full_moon_event.active_or_upcoming?

    # Schedule the event
    full_moon_event.update(start_at: start_of_event, finish_at: end_of_event)
  end
end
