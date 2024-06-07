# frozen_string_literal: true

class Rack::Attack
  if Rails.env.production?
    # Block all traffic from 1.2.3.4
    # blocklist('block 1.2.3.4') do |req|
    #   '1.2.3.4' == req.ip
    # end

    # Throttle requests to 5 requests per second per IP address
    throttle('req/ip', limit: 5, period: 1.second) do |req|
      req.ip
    end

    # Throttle login attempts to 5 requests per minute per IP address
    # throttle('logins/ip', limit: 5, period: 60.seconds) do |req|
    #   if req.path == '/login' && req.post?
    #     req.ip
    #   end
    # end

    # You can use the request method to determine more complex rules
    # throttle('req/path', limit: 10, period: 1.minute) do |req|
    #   if req.path.start_with?('/api/v1/') && req.get?
    #     req.ip
    #   end
    # end

    # Return custom response for throttled requests
    self.throttled_responder = lambda do |env|
      retry_after = (env['rack.attack.match_data'] || {})[:period]
      [
        429,
        { 'Content-Type' => 'application/json', 'Retry-After' => retry_after.to_s },
        [{ error: 'Throttle limit reached. Retry later.' }.to_json],
      ]
    end
  end
end
