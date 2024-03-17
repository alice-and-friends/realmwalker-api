# frozen_string_literal: true

class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :xp_level_report, :base, :preferences

  def base
    return nil if object.base.nil?

    {
      id: object.base.id,
      coordinates: object.base.coordinates,
    }
  end
end
