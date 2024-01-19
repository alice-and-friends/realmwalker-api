# frozen_string_literal: true

class Api::V1::MonstersController < ApplicationController
  def index

    # Common locations
    @monsters = Monster.all

    render json: @monsters, each_serializer: MonsterSerializer
  end
end
