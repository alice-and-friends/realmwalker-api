# realmwalker-api
Hello.

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

## Running the application
* `rails s` Start the Rails server

## Services
Our application leverages Redis as a data store for Sidekiq, which is used for background job processing. Sidekiq-Cron is utilized to schedule recurring jobs, and Sidekiq-Web provides a web interface for monitoring and managing the job queue and scheduled jobs.
* `redis-server` Start the Redis server
* `sidekiq` Start Sidekiq
* `rake sidekiq purge` Purge all scheduled jobs (should probably not be used in production)

Access the Sidekiq Web UI at http://localhost:3000/sidekiq to monitor and manage jobs.

## Utilities
* `rake geography:list` Shows a list of geography files and their last edited date
* `rake geography:stats` Shows the number of database records (RealWorldLocation) for each geography
* `rake geography:chart` Shows a visual bar chart representing the relative sizes of the geography files

## Code- and naming conventions
### Validators
Custom validator names should begin with the word 'must'.  Example:
```ruby
validate awesomeness # Bad
validate must_be_awesome # Good
```
### Latitude and Longitude
The world can not agree on a standard for the order of these two. Google and OpenStreetMaps use latitude-first, and Postgis uses longitude-first.
In this codebase, the convention is to use latitude-first, except when interacting directly with the database, which uses Postgis. Example:
```ruby
def cool_function(latitude, longitude) {} # Good
def cool_function(longitude, latitude) {} # Bad
where("ST_DWithin(coordinates, 'POINT(#{longitude} #{latitude})', #{1_000})") # Good
where("ST_DWithin(coordinates, 'POINT(#{latitude} #{longitude})', #{1_000})") # Bad
```
### Geographies and Regions
"Geography" or "Geographies" refers to datasets gathered from OpenStreetMaps, before importing to RealmWalker. In this context, "geographies" refers to the different geographic characteristics of a region, as described in OSM.
"Region(s)" is used to categorize location data after import. Geographies and regions typically map 1-to-1, though this is not guaranteed.
## Abbreviations and initialisms
Like with most style code repositories, abbreviations are generally frowned upon.
```ruby
object.latitude = 1234 # Good
object.lat = 1234 # Bad
```
## Testing
`rails test`

## Deployment instructions
...
