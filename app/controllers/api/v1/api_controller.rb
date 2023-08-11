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
    if Rails.env.test?
      @current_user = User.first
      return
    end

    return if http_token.nil?

    auth0_user, err = Auth0Helper.identify(http_token)
    if err.kind_of? Net::HTTPTooManyRequests
      render json: { message: "Too many requests" }, status: :too_many_requests and return
    elsif err
      render json: { message: "Unknown error from Auth0 helper in identify_user" }, status: :internal_server_error and return
    end

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
      @current_user.save!
    else
      puts '@current_user is not a valid object, see errors below:', @current_user.errors.inspect
      render json: { message: 'Unable to set current resource owner due to validation errors, please check the server log.' }, status: :internal_server_error
    end
  end
end
