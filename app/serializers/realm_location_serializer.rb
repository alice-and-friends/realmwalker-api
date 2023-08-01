class RealmLocationSerializer < ActiveModel::Serializer
  attributes :id, :location_type, :name, :coordinates, :location_map_detail
end
