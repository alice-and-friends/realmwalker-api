class Auth0UserData
  attr_accessor :sub, :given_name, :family_name, :email

  include Serializable # https://codeburst.io/json-serialized-columns-with-rails-a610a410fcdf
end
