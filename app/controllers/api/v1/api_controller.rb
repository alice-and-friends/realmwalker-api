# All other API controllers are subclasses of this class
class Api::V1::ApiController < ApplicationController
  include Secured
  before_action :authorize
  before_action :identify_user

  private

  def http_token
    if request.headers['Authorization'].present?
      request.headers['Authorization'].split(' ').last
    end
  end

  def identify_user
    return if http_token.nil?

    auth0_user = Auth0Helper.identify(http_token)
    @current_user = User.find_by(auth0_user_id: auth0_user.sub)

    if @current_user
      # Update existing user
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
    else
      puts '@current_user is not a valid object, see errors below:', @current_user.errors.inspect
      render json: { message: 'Unable to set current resource owner due to validation errors, please check the server log.' }, status: :internal_server_error
    end
  end
end
