# frozen_string_literal: true

# Usage example:
#   # Access the SpatialFactoryStore instance
#   factory_store = RGeo::ActiveRecord::SpatialFactoryStore.instance
#
#   # Fetch the factory registered for point columns
#   point_factory = factory_store.factory(geo_type: 'point')
#
#   # Use the point factory to create a new point
#   new_point = point_factory.point(longitude, latitude)

RGeo::ActiveRecord::SpatialFactoryStore.instance.tap do |config|
  # By default, use the GEOS implementation for spatial columns.
  config.default = RGeo::Geos.factory

  # But use a geographic implementation for point columns.
  config.register(RGeo::Geographic.spherical_factory(srid: 4326, has_z_coordinate: false), geo_type: 'point')
end
