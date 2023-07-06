# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

require 'csv'

csv_text = File.read(Rails.root.join('lib', 'seeds', 'real_world_locations.csv'))
csv = CSV.parse(csv_text, :headers => true, :encoding => 'ISO-8859-1')
csv.each do |row|
  loc = RealWorldLocation.new()
  loc.name = row['name']
  loc.ext_id = row['ext_id']
  loc.type = row['type']
  loc.coordinates = ActiveRecord::Point.new(row['lat'], row['lon'])
  if loc.valid?
    loc.save
    puts "CREATED #{loc.name}"
  else
    puts loc.errors.inspect
  end
end

Location.generate_dungeon!
