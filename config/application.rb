# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# Load dotenv only in development or test environment
if %w[development test].include? ENV['RAILS_ENV']
  Dotenv::Railtie.load
end

module RealmwalkerApi
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    # Configure Sidekiq as the queue adapter for Active Job
    config.active_job.queue_adapter = :sidekiq

    # Olive branch lets your API users pass in and receive camelCased or dash-cased keys,
    # while your Rails app receives and produces snake_cased ones.
    # https://github.com/vigetlabs/olive_branch
    excluded_routes = ->(env) { !env['PATH_INFO'].match(%r{^/api}) }
    config.middleware.use OliveBranch::Middleware,
                          inflection:       'camel',
                          exclude_params:   excluded_routes,
                          exclude_response: excluded_routes
  end
end
