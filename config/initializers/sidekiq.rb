# frozen_string_literal: true

require 'sidekiq'
require 'sidekiq/web'
require 'sidekiq-cron'
require 'sidekiq/cron/web'

Sidekiq.configure_client do |config|
  Sidekiq.logger.level = Logger::WARN
end

Sidekiq.configure_server do |config|
  schedule_file = 'config/schedule.yml'

  if File.exist?(schedule_file) && Sidekiq.server?
    Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file)
  end
end

# Define job schedule
# Useful cron expression generator: https://crontab.cronhub.io/
# WARNING: Changing the names of jobs may result in duplicate cron schedules. Schedules can be disabled and removed in the Sidekiq Web UI.
Sidekiq::Cron::Job.create(
  name: 'Create new dungeons',
  cron: '0/2 * * * *', # Every 2 minutes
  class: 'DungeonCreateWorker',
  timezone: 'UTC',
)
Sidekiq::Cron::Job.create(
  name: 'Schedule dungeon expirations',
  cron: '1/2 * * * *', # Every 2 minutes, starting at 1 minutes past the hour (to avoid conflict with 'Create new dungeons')
  class: 'DungeonExpirationScheduler',
  timezone: 'UTC',
)
Sidekiq::Cron::Job.create(
  name: 'Destroy expired dungeons',
  cron: '0 * * * *', # Every hour
  class: 'DungeonDestroyWorker',
  timezone: 'UTC',
)
