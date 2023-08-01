class MonsterSerializer < ActiveModel::Serializer
  attributes :name, :description, :level, :classification, :tags
end
