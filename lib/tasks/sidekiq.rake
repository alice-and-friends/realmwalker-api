# frozen_string_literal: true

namespace :sidekiq do
  desc 'Purge all scheduled jobs and retries from Sidekiq'
  task purge: :environment do
    require 'sidekiq/api'

    # Purge Scheduled Jobs
    scheduled_set = Sidekiq::ScheduledSet.new
    scheduled_set.clear

    # Purge Retries
    retries_set = Sidekiq::RetrySet.new
    retries_set.clear

    puts 'All scheduled jobs and retries have been purged from Sidekiq.'
  end
end
