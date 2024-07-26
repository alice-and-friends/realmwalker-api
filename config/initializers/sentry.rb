# frozen_string_literal: true

Sentry.init do |config|
  config.dsn = ENV.fetch('SENTRY_DSN', nil)
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]

  # Ensure Sentry captures logger messages
  config.logger = Rails.logger

  # Optionally send environment information
  config.environment = Rails.env

  # Optionally set the release
  # config.release = 'my-project@2.3.12'

  # Set traces_sample_rate to 1.0 to capture 100%
  # of transactions for performance monitoring.
  # We recommend adjusting this value in production.
  config.traces_sample_rate = 1.0
  # or
  config.traces_sampler = lambda do |context|
    true
  end
  # Set profiles_sample_rate to profile 100%
  # of sampled transactions.
  # We recommend adjusting this value in production.
  config.profiles_sample_rate = 1.0

  # Enable capturing of exceptions
  # config.excluded_exceptions -= %w[ActiveRecord::RecordNotFound ActionController::RoutingError]
end
