# frozen_string_literal: true

require 'jwt'
require 'net/http'

class Auth0Helper

  # Auth0 Client Objects
  Error = Struct.new(:message, :status)
  Response = Struct.new(:decoded_token, :error)

  # Token = Struct.new(:token) do
  #   def validate_permissions(permissions)
  #     required_permissions = Set.new permissions
  #     scopes = token[0]['scope']
  #     token_permissions = scopes.present? ? Set.new(scopes.split(' ')) : Set.new
  #     required_permissions <= token_permissions
  #   end
  # end

  # Helper Functions
  def self.domain_url
    "https://#{ENV.fetch('AUTH0_DOMAIN')}/"
  end

  def self.decode_token(token, jwks_hash)
    JWT.decode(token, nil, true, {
                 algorithm: 'RS256',
                 iss: domain_url,
                 verify_iss: true,
                 aud: ENV.fetch('AUTH0_AUDIENCE'),
                 verify_aud: true,
                 jwks: { keys: jwks_hash[:keys] },
               })
  end

  # Get JSON Web Key Set from Auth0
  def self.jwks
    jwks_uri = URI("#{domain_url}.well-known/jwks.json")
    Net::HTTP.get_response jwks_uri
  end

  # Token Validation
  def self.validate_token(token)
    jwks_response = jwks

    unless jwks_response.is_a? Net::HTTPSuccess
      error = Error.new(message: 'Unable to verify credentials', status: :internal_server_error)
      return Response.new(nil, error)
    end

    jwks_hash = JSON.parse(jwks_response.body).deep_symbolize_keys

    decoded_token = decode_token(token, jwks_hash)

    # Response.new(Token.new(decoded_token), nil)
    [decoded_token, nil]
  rescue JWT::VerificationError, JWT::DecodeError => e
    error = Error.new('Bad credentials', :unauthorized)
    # Response.new(nil, error)
    [nil, error]
  end

  def self.get_user(access_token)
    uri = URI("#{domain_url}userinfo")
    req = Net::HTTP::Get.new(uri)
    req['Authorization'] = "Bearer #{access_token}"
    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(req)
    end
    json = JSON.parse(res.body, symbolize_names: true)

    return Auth0UserData.new(json), nil if res.is_a? Net::HTTPSuccess

    [nil, res] # error
  end
end
