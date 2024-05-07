# frozen_string_literal: true

class RegionValidator < ActiveModel::EachValidator
  REALMWALKER_REGIONS = [

    # Special regions
    'Azores', # Extension of Portugal
    'CanaryIslands', # Extension of Spain
    'GuernseyAndJersey', # Crown dependency
    'IrelandAndNorthernIreland', # Two countries mashed together
    'Italy', # Includes Vatican City and San Marino

    # Countries, Americas
    'Canada',
    'US',

    # Countries, Europe
    'Albania',
    'Andorra',
    'Austria',
    'Belarus',
    'Belgium',
    'BosniaAndHerzegovina',
    'Bulgaria',
    'Croatia',
    'Cyprus',
    'CzechRepublic',
    'Denmark',
    'England',
    'Estonia',
    'FaroeIslands',
    'Finland', # Includes Åland
    'France', # Includes Corsica
    'Georgia',
    'Germany',
    'Greece',
    'Hungary',
    'Iceland',
    'IsleofMan',
    'Kosovo',
    'Latvia',
    'Liechtenstein',
    'Lithuania',
    'Luxembourg',
    'Macedonia',
    'Malta',
    'Moldova',
    'Monaco',
    'Montenegro',
    'Netherlands',
    'Norway',
    'Poland',
    'Portugal',
    'Romania',
    'Scotland',
    'Serbia',
    'Slovakia',
    'Slovenia',
    'Spain',
    'Sweden',
    'Switzerland',
    'Turkey',
    'Wales',
  ].freeze

  def validate_each(record, attribute, value)
    # Regions that begin with "_" can bypass validation. These are used for development and testing purposes.
    return if value.first == '_'

    # Some regions are divided into subregions (e.g. US-NY). We will not validate subregions since they can change quite often.
    region_without_subregion = value.split('-').first

    # Ensure that the value is a valid region
    record.errors.add(attribute, 'not a valid Realmwalker region') unless region_without_subregion.in? REALMWALKER_REGIONS
  end
end
