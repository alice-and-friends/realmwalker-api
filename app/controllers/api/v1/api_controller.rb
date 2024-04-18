# frozen_string_literal: true

# All other API controllers are subclasses of this class
class Api::V1::ApiController < ApplicationController
  before_action :geolocate
  before_action :authorize
  before_action :auth_debug if Rails.env.development?

  private

  def geolocate
    latitude, longitude = request.headers['Geolocation']&.split&.map(&:to_f)
    if latitude.present? && longitude.present?
      factory_store = RGeo::ActiveRecord::SpatialFactoryStore.instance # Access the SpatialFactoryStore instance
      point_factory = factory_store.factory(geo_type: 'point') # Fetch the factory registered for point columns
      @current_user_geolocation = {
        latitude: latitude,
        longitude: longitude,
        point: point_factory.point(longitude, latitude), # Use the point factory to create a new point,
      }
    else
      render json: { message: 'Geolocation missing' }, status: :bad_geolocation
    end
  end

  def authorize
    if Rails.env.test?
      @current_user = User.first
      return
    end

    access_token = request.headers['Authorization']&.split&.last
    render json: { message: 'Token missing' }, status: :unauthorized and return if access_token.blank?

    user = User.find_by_access_token(access_token) # rubocop:disable Rails/DynamicFindBy
    if user.present?
      @current_user = user
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
    @current_user = User.find_or_initialize_by(auth0_user_id: auth0_user.sub)
    token_expiration = decoded_token[0]['exp']
    @current_user.update(
      auth0_user_data: auth0_user,
      access_token: access_token,
      access_token_expires_at: Time.at(token_expiration).in_time_zone.to_datetime,
    )
    if @current_user.valid?
      @current_user.save!
    else
      puts '@current_user is not a valid object, see errors below:', @current_user.errors.inspect
      render json: { message: 'Unable to set current user due to validation errors, please check the server log.' }, status: :internal_server_error
    end
  end

  def auth_debug
    puts "📥 Processing request for authenticated user #{@current_user.auth0_user_id} AKA #{@current_user.name}"
  end
end
