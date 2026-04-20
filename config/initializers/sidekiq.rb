redis_config = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }
redis_config[:ssl_params] = { verify_mode: OpenSSL::SSL::VERIFY_NONE } if ENV["REDIS_URL"]&.start_with?("rediss://")

Sidekiq.configure_server do |config|
  config.redis = redis_config
  # Upstash free tier: 500k requests/month.
  # Default heartbeat cada 5s genera ~2M cmds/mes (4 cmds × 12/min × 60 × 24 × 30).
  # A 60s se reducen a ~43k cmds/mes. Sidekiq 8 usa acceso hash; el setter
  # heartbeat_interval= fue removido en v8.
  config[:heartbeat_interval] = 60
end

Sidekiq.configure_client do |config|
  config.redis = redis_config
end
