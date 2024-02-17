# frozen_string_literal: true

def csv_files
  directory = 'lib/seeds/geographies' # Change this to your directory path
  Dir.glob("#{directory}/*.csv").sort # Sort the array of file paths alphabetically
end

namespace :geography do
  desc 'List CSV files and their last commit dates'
  task list: :environment do
    printf("%-30s\t%s\n", 'Filename', 'Last Commit Date')
    puts '-' * 60 # Adjust the separator length based on the column width

    csv_files.each do |file|
      last_commit_date_str = `git log -1 --format="%cd" --date=format:%Y-%m-%d -- #{file}`.chomp
      if last_commit_date_str.empty?
        printf("%-30s\t%s\n", File.basename(file), 'No commits found')
        next
      end
      last_commit_date = Date.parse(last_commit_date_str)
      days_ago = (Date.today - last_commit_date).to_i
      printf("%-30s\t%s (%d days ago)\n", File.basename(file), last_commit_date_str, days_ago)
    end
  end

  task stats: :environment do
    printf("%-30s\t%s\n", 'Region', 'Number of records in database')
    puts '-' * 65 # Adjust the separator length based on the column width

    expected_geographies = csv_files.map{ |file| File.basename(file, '.csv') }

    # Query to count records per region
    stats = RealWorldLocation.group(:region).count

    # Displaying the statistics
    stats.each do |region, count|
      printf("%-30s\t%s\n", region, count)
      expected_geographies.delete(region)
    end

    # List any missing geographies
    printf("\nNo records found for: %s\n", expected_geographies.join(', '))
    # expected_geographies.each do |region|
    #   printf("%-30s\t%s\n", region, 0)
    # end
  end
end
