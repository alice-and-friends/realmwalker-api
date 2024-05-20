# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'database_cleaner/active_record'
require 'rails/test_help'

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  # parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  DatabaseCleaner.strategy = :deletion, { except: %w[spatial_ref_sys] }
  DatabaseCleaner.clean_with :truncation, { except: %w[spatial_ref_sys] }
  Rails.application.load_seed
  self.use_instantiated_fixtures = true
  fixtures :all

  def generate_test_user_location
    RealWorldLocation.point_factory.point(10.702654, 59.926097) # Do not edit
  end

  def generate_nearby_location
    RealWorldLocation.point_factory.point(10.703246, 59.926556) # Do not edit
  end

  def generate_far_away_location
    RealWorldLocation.point_factory.point(10.739660, 59.925807) # Do not edit
  end

  def generate_headers
    location = generate_test_user_location
    { Geolocation: "#{location.latitude} #{location.longitude}" }
  end

  def generate_test_user
    test_user_name = Faker::Name.first_name
    test_user_unique = Faker::Number.unique.number(digits: 10)
    User.create!(
      auth0_user_id: test_user_unique,
      auth0_user_data: Auth0UserData.new(
        sub: "test|#{test_user_unique}",
        given_name: test_user_name,
        family_name: '',
        email: Faker::Internet.email(name: test_user_name),
      )
    )
  end

  def generate_test_renewable
    Renewable.create!(real_world_location: RealWorldLocation.available.sample)
  end

  # Custom assertion to check a user object for sensitive data
  def assert_safe_user_object(user)
    assert_nil user['id']
    assert_nil user['email']
    assert_nil user['auth0UserId']
    assert_nil user['auth0UserData']
    assert_nil user['inventory']
    assert_nil user['base']
    assert_nil user['accessToken']
    assert_nil user['accessTokenExpiresAt']
    assert_nil user['preferences']
  end
end
