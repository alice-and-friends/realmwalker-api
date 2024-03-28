# frozen_string_literal: true

class Api::V1::HomeController < Api::V1::ApiController
  def home
    render json: { server_time: Time.current, events: [] }
  end
end
