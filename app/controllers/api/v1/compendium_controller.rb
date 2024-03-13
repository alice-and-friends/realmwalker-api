# frozen_string_literal: true

class Api::V1::CompendiumController < ApplicationController
  def monsters
    @monsters = Monster.all
    render json: @monsters, each_serializer: MonsterSerializer, compendium: true
  end

  def items
    @items = Item.all
    render json: @items, each_serializer: ItemSerializer, compendium: true
  end
end
