class Auth0Helper
  DOMAIN = ENV['AUTH0_DOMAIN']
  @access_token = ''

  def self.identify(access_token)
    @access_token = access_token
    return self.get_user
  end

  def self.get_user
    uri = URI("https://#{DOMAIN}/userinfo")
    req = Net::HTTP::Get.new(uri)
    req['Authorization'] = "Bearer #{@access_token}"
    puts "calling #{uri.hostname}"
    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) {|http|
      http.request(req)
    }
    puts res.body.inspect
    json = JSON.parse(res.body, symbolize_names: true)
    return Auth0UserData.new(json)
  end
end
