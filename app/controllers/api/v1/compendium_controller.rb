# frozen_string_literal: true

class Api::V1::CompendiumController < ApplicationController
  before_action :env_guard

  def monsters
    @monsters = Monster.all
    render json: @monsters, each_serializer: MonsterSerializer, compendium: true
  end

  def items
    @items = Item.all
    render json: @items, each_serializer: ItemSerializer, compendium: true
  end

  def portraits
    portraits = Portrait.all
    render json: portraits, each_serializer: PortraitSerializer, compendium: true
  end

  private

  def env_guard
    render status: :method_not_allowed if Rails.env.production?
  end
end
