# frozen_string_literal: true

class SystemCheckService
  def self.redis_running?
    redis = Redis.new(url: "redis://#{ENV.fetch('REDIS_HOST')}:#{ENV.fetch('REDIS_PORT')}") # Update with your Redis config
    redis.ping == 'PONG'
  rescue Redis::CannotConnectError
    false
  end

  def self.sidekiq_running?
    Sidekiq::ProcessSet.new.size.positive?
  rescue StandardError => e
    Rails.logger.error "Failed to check Sidekiq status: #{e.message}"
    false
  end
end
