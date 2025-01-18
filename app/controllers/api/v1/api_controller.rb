# frozen_string_literal: true

# All other API controllers are subclasses of this class
class Api::V1::ApiController < ApplicationController
  before_action :geolocate
  before_action :authorize
  before_action :auth_debug if Rails.env.development?

  private

  def geolocate
    latitude, longitude = request.headers['Geolocation']&.split&.map(&:to_f)

    if request.params['debug']
      @current_user_geolocation = RealWorldLocation.point_factory.point(10.702654, 59.926097)
    elsif latitude.present? && longitude.present?
      @current_user_geolocation = RealWorldLocation.point_factory.point(longitude, latitude) # Use the point factory to create a new point
    else
      render json: { message: 'Geolocation missing' }, status: :bad_geolocation
    end
  end

  def authorize
    if Rails.env.test?
      @current_user = User.first # Should get test user "Jane Doe" from fixtures
      return
    end

    access_token = request.headers['Authorization']&.split&.last
    render json: { message: 'Token missing' }, status: :unauthorized and return if access_token.blank?

    # NB: find_by_access_token will return nil if the token is expired
    user = User.find_by_access_token(access_token) # rubocop:disable Rails/DynamicFindBy
    if user.present?
      @current_user = user
      puts "🔑✅ Successfully authenticated returning user #{current_user_log_str}"
      return
    end

    # Validate token against Auth0
    decoded_token, err = Auth0Helper.validate_token(access_token)
    render json: { message: err.message }, status: :err.status and return if err

    # Get user data from Auth0
    auth0_user, err = Auth0Helper.get_user(access_token)
    if err.is_a? Net::HTTPTooManyRequests
      render json: { message: 'Too many requests' }, status: :too_many_requests and return
    elsif err
      render json: { message: 'Unknown error from Auth0 helper in identify_user' }, status: :internal_server_error and return
    end

    # Check if we have a matching user, or create a new one
    @current_user = User.find_or_initialize_by(email: auth0_user.email)
    token_expiration = decoded_token[0]['exp']
    @current_user.update(
      auth0_user_id: auth0_user.sub,
      auth0_user_data: auth0_user,
      access_token: access_token,
      access_token_expires_at: Time.at(token_expiration).in_time_zone.to_datetime,
    )
    if @current_user&.valid?
      @current_user.save!
      puts "🔑⚙️ Assigned new access token to user #{current_user_log_str}"
    else
      puts '@current_user is not a valid object, see errors below:', @current_user.errors.inspect
      puts 'auth0_user:', auth0_user.inspect
      render json: { message: 'Unable to set current user due to validation errors, please check the server log.' }, status: :internal_server_error
    end
  end

  def auth_debug
    puts "📥 Processing request for authenticated user #{current_user_log_str}"
  end

  # Overwrite the default render method, ensure errors are logged
  def render(options = nil, extra_options = {}, &block)
    if options.is_a?(Hash) && options[:status]
      status_code = Rack::Utils::SYMBOL_TO_STATUS_CODE[options[:status]] || options[:status]
      Rails.logger.error "Rendered #{status_code}: #{options[:json] || options[:text]}" if status_code.to_i >= 400
    end
    super(options, extra_options, &block)
  end

  def current_user_log_str
    "#{@current_user&.auth0_user_id} a.k.a. \"#{@current_user&.name}\""
  end
end
