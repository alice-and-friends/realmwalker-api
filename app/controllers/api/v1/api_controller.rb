# All other API controllers are subclasses of this class
class Api::V1::ApiController < ApplicationController
  before_action :identify_user

  private

  def http_token
    if request.headers['Authorization'].present?
      request.headers['Authorization'].split(' ').last
    end
  end

=begin
  def auth0_client
    @auth0_client ||= Auth0Client.new(
      client_id: ENV['AUTH0_CLIENT_ID'],
      client_secret: ENV['AUTH0_CLIENT_SECRET'],
      # If you pass in a client_secret value, the SDK will automatically try to get a
      # Management API token for this application. Make sure your Application can make a
      # Client Credentials grant (Application settings in Auth0 > Advanced > Grant Types
      # tab) and that the Application is authorized for the Management API:
      # https://auth0.com/docs/api-auth/config/using-the-auth0-dashboard
      #
      # Otherwise, you can pass in a Management API token directly for testing or temporary
      # access using the key below.
      # token: ENV['AUTH0_RUBY_API_TOKEN'],
      #
      # When passing a token, you can also specify when the token expires in seconds from epoch. Otherwise, expiry is set
      # by default to an hour from now.
      # token_expires_at: Time.now.to_i + 86400,
      domain: ENV['AUTH0_DOMAIN'],
      api_version: 2,
      timeout: 15 # optional, defaults to 10
    )
  end
=end

  def identify_user
    auth0_user = Auth0Helper.identify(http_token)
    @current_user = User.find_by(auth0_user_id: auth0_user.sub)

    if @current_user
      # Update existng user
      @current_user.auth0_user_data = auth0_user
    else
      # Create new user
      @current_user = User.new(
        auth0_user_id: auth0_user.sub,
        auth0_user_data: auth0_user
      )
    end
    if @current_user.valid?
      unless @current_user.save
        render json: { message: 'Unable to set current resource owner' }, status: :internal_server_error
      end
    end
  end

  def set_current_resource_owner
    err, auth0_user = Auth0Helper.identify(http_token)
    if err
      render status: :internal_server_error
    end
    unless auth0_user[:sub]
      puts "auth0[:sub] was #{auth0_user[:sub]}"
      render json: { errors: ['Authentication failed'] }, status: :unauthorized
    end
    @current_resource_owner ||= User.find(auth0_user[:sub])
    puts @current_resource_owner
  end
end
