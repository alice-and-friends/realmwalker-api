ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require 'database_cleaner/active_record'

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  DatabaseCleaner.strategy = :truncation
  DatabaseCleaner.clean
  Rails.application.load_seed
  self.use_instantiated_fixtures = true
  fixtures :all

  # Add more helper methods to be used by all tests here...
  #
end
