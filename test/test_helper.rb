ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'database_cleaner/active_record'
require 'rails/test_help'

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
  def generate_test_user
    test_user_name = Faker::Name.first_name
    test_user_unique = Faker::Number.unique
    User.create!(
      auth0_user_id: 'test_user_unique',
      auth0_user_data: Auth0UserData.new(
        sub: "test|#{test_user_unique}",
        given_name: test_user_name,
        family_name: '',
        email: Faker::Internet.email(name: test_user_name)
      )
    )
  end
end
