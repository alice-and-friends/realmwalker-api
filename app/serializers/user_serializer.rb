# frozen_string_literal: true

class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :xp_level_report
end
