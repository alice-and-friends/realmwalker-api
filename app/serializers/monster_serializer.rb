class MonsterSerializer < ActiveModel::Serializer
  attributes :name, :description, :level, :types
end
