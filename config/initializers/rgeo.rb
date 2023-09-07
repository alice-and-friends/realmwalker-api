# frozen_string_literal: true

# TODO: Unsure if this config does anything at all. Apps seems to work fine without it. I'll just leave it for now.
# https://github.com/rgeo/rgeo-activerecord#spatial-factories-for-columns

RGeo::ActiveRecord::SpatialFactoryStore.instance.tap do |config|
  # By default, use the GEOS implementation for spatial columns.
  config.default = RGeo::Geos.factory

  # But use a geographic implementation for point columns.
  config.register(RGeo::Geographic.spherical_factory(srid: 4326), geo_type: 'point')
end
