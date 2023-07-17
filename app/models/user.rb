class User < ApplicationRecord
  #store_accessor :preferences, :language
  #store_accessor :preferences, :voice

  serialize :auth0_user_data, Auth0UserData

  validates :auth0_user_id, presence: true, uniqueness: true
  validate :valid_auth0_user_data

  def email
    auth0_user_data.email
  end
  def given_name
    auth0_user_data.given_name
  end
  def family_name
    auth0_user_data.family_name
  end

  protected

  def valid_auth0_user_data
    errors.add(:auth0_user_data, 'is missing property sub') if auth0_user_data.sub.nil?
    errors.add(:auth0_user_data, 'is missing property given_name') if auth0_user_data.given_name.nil?
    errors.add(:auth0_user_data, 'is missing property family_name') if auth0_user_data.family_name.nil?
    # errors.add(:auth0_user_data, 'is missing property email') if auth0_user_data.email.nil?
  end
end
