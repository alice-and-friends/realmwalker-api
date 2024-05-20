# frozen_string_literal: true

require 'sidekiq'
require 'sidekiq/web'
require 'sidekiq-cron'
require 'sidekiq/cron/web'

Sidekiq.configure_client do |config|
  Sidekiq.logger.level = Logger::WARN
end

Sidekiq.configure_server do |config|
  config.average_scheduled_poll_interval = 5

  schedule_file = 'config/schedule.yml'
  if File.exist?(schedule_file) && Sidekiq.server?
    Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file)
  end
end

Rails.application.config.after_initialize do
  unless Sidekiq::ScheduledSet.new.any? { |job| job['class'] == RenewableGrowthWorker.name }
    RenewableGrowthWorker.perform_at(Renewable.next_growth_at)
  end
end
