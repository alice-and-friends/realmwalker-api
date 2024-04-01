# frozen_string_literal: true

class EventSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :start_at, :finish_at, :active

  def active
    object.active?
  end
end
