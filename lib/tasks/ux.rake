# frozen_string_literal: true

namespace :ux do
  desc 'Shows runestone info'
  task runestones: :environment do
    template = "%-30s\t%-30s\n"
    printf(template, 'Region', 'Number of distinct runestones')
    puts '-' * 65


    results = Runestone.select('region, COUNT(DISTINCT name) as distinct_names_count').group(:region)
    results.each do |record|
      set_str = "#{record.distinct_names_count} / #{RunestonesHelper.count}".rjust(7)
      set_str += ' (complete set)' if record.distinct_names_count >= RunestonesHelper.count
      printf(template, record.region, set_str)
    end

    origins = [
      { region: 'Norway',  name: 'Oslo Opera House',    coordinates: RealWorldLocation.point_factory.point(10.752280, 59.907756) },
      { region: 'Norway',  name: 'Sandvika Storsenter', coordinates: RealWorldLocation.point_factory.point(10.520303, 59.890146) },
      { region: 'Sweden',  name: 'Halmstad Arena',      coordinates: RealWorldLocation.point_factory.point(12.890496, 56.674155) },
      { region: 'Sweden',  name: 'Ullared',             coordinates: RealWorldLocation.point_factory.point(12.717992, 57.136257) },
      { region: 'Germany', name: 'Alexanderplatz',      coordinates: RealWorldLocation.point_factory.point(13.413624, 52.521699) },
    ]
    puts "\n"
    origins.each do |origin|
      longest_distance = 0
      RunestonesHelper.all.each do |runestone|
        nearest = Runestone.where(runestone_id: runestone.id).nearest(origin[:coordinates].latitude, origin[:coordinates].longitude)
        longest_distance = nearest.distance if nearest.distance > longest_distance
      end
      puts "Starting from #{origin[:name]} in #{origin[:region]}, all runestones can be found within a radius of #{(longest_distance / 1000).ceil} kilometers."
    end
  end
end
