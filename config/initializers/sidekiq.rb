redis_config = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }
redis_config[:ssl_params] = { verify_mode: OpenSSL::SSL::VERIFY_NONE } if ENV["REDIS_URL"]&.start_with?("rediss://")

Sidekiq.configure_server do |config|
  config.redis = redis_config
  # Free-tier Upstash has a 500k requests/month cap.
  # Default heartbeat is every 5s (~518k req/month solo en heartbeats).
  # Increasing to 30s reduces heartbeat cost to ~86k req/month.
  config.heartbeat_interval = 30
end

Sidekiq.configure_client do |config|
  config.redis = redis_config
end
