class RealmLocationSerializer < ActiveModel::Serializer
  attributes :id, :location_type, :name, :coordinates
end
