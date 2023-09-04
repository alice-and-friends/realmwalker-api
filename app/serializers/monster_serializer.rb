# frozen_string_literal: true

class MonsterSerializer < ActiveModel::Serializer
  attributes :name, :description, :level, :classification, :tags
end
