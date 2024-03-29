# frozen_string_literal: true

class Api::V1::HomeController < Api::V1::ApiController
  def home
    events = {
      active: Event.active,
      upcoming: Event.upcoming,
    }
    render json: { server_time: Time.current, events: events }
  end
end
