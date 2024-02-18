# frozen_string_literal: true

def csv_files
  directory = 'lib/seeds/geographies' # Change this to your directory path
  Dir.glob("#{directory}/*.csv").sort # Sort the array of file paths alphabetically
end

def geography_file_score(file_size_mb, days_since_last_update)
  score = file_size_mb - days_since_last_update
  grade = if score >= -90
            '🟢 Excellent'
          elsif score >= -180
            '🟢 Good'
          elsif score >= -365
            '🟡 OK'
          else
            '🔴 Needs update'
          end
  [score, grade]
end

namespace :geography do
  desc 'List geography CSV files and their last commit dates'
  task list: :environment do
    template = "%-30s\t%-10s\t%-16s\t%-30s\n"
    printf(template, 'Filename', 'Size (KB)', 'Health score', 'Last Commit Date')
    puts '-' * 95 # Adjust the separator length based on the column width

    csv_files.each do |file|
      file_size = (File.size(file) / (1024 * 1024).to_f).ceil
      size_str = "#{file_size.to_fs(:delimited)}".rjust(9)
      last_commit_date_str = `git log -1 --format="%cd" --date=format:%Y-%m-%d -- #{file}`.chomp
      if last_commit_date_str.empty?
        printf(template, File.basename(file), size_str, '', 'No commits found')
        next
      end
      last_commit_date = Date.parse(last_commit_date_str)
      days_ago = (Time.zone.today - last_commit_date).to_i
      _, health_grade = geography_file_score(file_size, days_ago)
      printf(template, File.basename(file), size_str, health_grade, "#{last_commit_date_str} (#{days_ago.to_fs(:delimited)} days ago)")
    end
  end

  desc 'List geographies and show how many corresponding locations are in the database'
  task stats: :environment do
    printf("%-30s\t%s\n", 'Region', 'Number of records in database')
    puts '-' * 65 # Adjust the separator length based on the column width

    expected_geographies = csv_files.map{ |file| File.basename(file, '.csv') }

    # Query to count records per region
    stats = RealWorldLocation.group(:region).count

    # Displaying the statistics
    stats.each do |region, count|
      printf("%-30s\t%s\n", region, count.to_fs(:delimited).rjust(7))
      expected_geographies.delete(region)
    end

    # List any missing geographies
    printf("\nTotal records: %s\n", RealWorldLocation.count.to_fs(:delimited))
    printf("No records found for: %s\n", expected_geographies.join(', '))
  end
end
