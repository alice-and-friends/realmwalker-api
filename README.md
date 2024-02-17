# realmwalker-api

Hello

## System dependencies
* Ruby version as described in Gemfile
* Python 3 and Osmium (for generating geography files)

## Configuration
Environment variables...

## Database creation
`rake db:create db:migrate`

## Database initialization
* `rake db:seed globals=yes` Creates non-geographical data such as monsters, items
* `rake db:seed geographies=Sweden,Norway` Creates geographical data for specified regions
* `rake db:seed geographies=all` Creates geographical data for all region (takes a long time)

## Utilities
* `rake geography:list` Shows a list of geography files and their last edited date
* `rake geography:stats` Shows the number of database records (RealWorldLocation) for each geography

## Code- and naming conventions
**Latitude and Longitude:**
The world can not agree on a standard for the order of these two. Google and OpenStreetMaps use latitude-first, and Postgis uses longitude-first.
In this codebase, the convention is to use latitude-first, except when interacting directly with the database, which uses Postgis. Example:
```ruby
scope :near, lambda { |latitude, longitude, distance|
  where("ST_DWithin(coordinates, 'POINT(#{longitude} #{latitude})', #{distance})")
}
```

## Testing
`rails test`

## Services (job queues, cache servers, search engines, etc.)

## Deployment instructions
...
