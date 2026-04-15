# config/initializers/rack_attack.rb
#
# Rate limiting por capas:
#   1. Auth endpoints (sign_in, refresh, forgot_password) — límites estrictos
#   2. API general                                         — límite amplio anti-scraping
#   3. Blocklist automático para IPs abusivas              — ban temporal de 1h

# ── Cache store ───────────────────────────────────────────────────────────────
# Wraps Redis with graceful fallback: if Redis is unavailable (e.g. Upstash
# monthly limit exceeded), all throttle checks return 0 so requests are
# allowed through instead of raising a 500.
class RackAttackSafeRedis
  RESCUED = [ Redis::CommandError, Redis::CannotConnectError,
              Redis::TimeoutError, RedisClient::CommandError ].freeze

  def initialize(url)
    ssl_params = { verify_mode: OpenSSL::SSL::VERIFY_NONE } if url.start_with?("rediss://")
    @redis = Redis.new(url: url, ssl_params: ssl_params)
  end

  def incr(key)
    @redis.incr(key)
  rescue *RESCUED => e
    Rails.logger.warn "[RackAttack] Redis unavailable — failing open (#{e.message.truncate(120)})"
    0
  end

  def expire(key, ttl)
    @redis.expire(key, ttl)
  rescue *RESCUED
    nil
  end

  def get(key)
    @redis.get(key)
  rescue *RESCUED
    nil
  end

  def setex(key, ttl, value)
    @redis.setex(key, ttl, value)
  rescue *RESCUED
    nil
  end

  def del(*keys)
    @redis.del(*keys)
  rescue *RESCUED
    nil
  end
end

Rack::Attack.cache.store = RackAttackSafeRedis.new(
  ENV.fetch("REDIS_URL", "redis://localhost:6379/1")
)

# ── Helpers ───────────────────────────────────────────────────────────────────

# Lee el email del body JSON de forma segura sin romper el stream
def req_email(req)
  body = JSON.parse(req.body.read) rescue {}
  req.body.rewind
  body.dig("user", "email").to_s.downcase.strip.presence
end

# ── 1. Throttles de autenticación ─────────────────────────────────────────────

# Login: 5 intentos por IP cada 20 segundos
Rack::Attack.throttle("auth/sign_in/ip", limit: 5, period: 20.seconds) do |req|
  req.ip if req.path == "/api/v1/auth/sign_in" && req.post?
end

# Login: 15 intentos por email por hora (para no bloquear usuarios legítimos en redes NAT)
Rack::Attack.throttle("auth/sign_in/email", limit: 15, period: 1.hour) do |req|
  req_email(req) if req.path == "/api/v1/auth/sign_in" && req.post?
end

# Refresh token: 20 renovaciones por IP por minuto
Rack::Attack.throttle("auth/refresh/ip", limit: 20, period: 1.minute) do |req|
  req.ip if req.path == "/api/v1/auth/refresh" && req.post?
end

# Forgot password: 5 solicitudes por IP por hora (evita email flooding)
Rack::Attack.throttle("auth/forgot_password/ip", limit: 5, period: 1.hour) do |req|
  req.ip if req.path == "/api/v1/auth/forgot_password" && req.post?
end

# Forgot password: 3 solicitudes por email por hora
Rack::Attack.throttle("auth/forgot_password/email", limit: 3, period: 1.hour) do |req|
  if req.path == "/api/v1/auth/forgot_password" && req.post?
    body = JSON.parse(req.body.read) rescue {}
    req.body.rewind
    body["email"].to_s.downcase.strip.presence
  end
end

# Registro: 5 cuentas por IP por hora (evita creación masiva de cuentas)
Rack::Attack.throttle("auth/sign_up/ip", limit: 5, period: 1.hour) do |req|
  req.ip if req.path == "/api/v1/auth/sign_up" && req.post?
end

# Verificación de email: 10 intentos por IP por hora
Rack::Attack.throttle("auth/verify_email/ip", limit: 10, period: 1.hour) do |req|
  req.ip if req.path == "/api/v1/auth/verify_email" && req.post?
end

# Reenvío de verificación: 5 por IP por hora, 3 por email por hora
Rack::Attack.throttle("auth/resend_verification/ip", limit: 5, period: 1.hour) do |req|
  req.ip if req.path == "/api/v1/auth/resend_verification" && req.post?
end

Rack::Attack.throttle("auth/resend_verification/email", limit: 3, period: 1.hour) do |req|
  if req.path == "/api/v1/auth/resend_verification" && req.post?
    body = JSON.parse(req.body.read) rescue {}
    req.body.rewind
    body["email"].to_s.downcase.strip.presence
  end
end

# ── 2. Throttle general de API ────────────────────────────────────────────────

# 300 requests por IP cada 5 minutos — protege contra scraping y DDoS ligero
Rack::Attack.throttle("api/general/ip", limit: 300, period: 5.minutes) do |req|
  req.ip if req.path.start_with?("/api/")
end

# ── 3. Blocklist automático (Allow2Ban) ───────────────────────────────────────

# Si una IP hace 30+ intentos de login en 1 hora → banear 24 horas
Rack::Attack.blocklist("auth/brute_force/ip") do |req|
  Rack::Attack::Allow2Ban.filter(req.ip,
    maxretry: 30,
    findtime: 1.hour,
    bantime:  24.hours
  ) do
    req.path == "/api/v1/auth/sign_in" && req.post?
  end
end

# ── Respuesta personalizada para throttled requests ───────────────────────────

Rack::Attack.throttled_responder = lambda do |req|
  match_data = req.env["rack.attack.match_data"]
  now        = match_data[:epoch_time]
  period     = match_data[:period]

  retry_after = (period - (now % period)).ceil

  headers = {
    "Content-Type"          => "application/json",
    "Retry-After"           => retry_after.to_s,
    "X-RateLimit-Limit"     => match_data[:limit].to_s,
    "X-RateLimit-Remaining" => "0",
    "X-RateLimit-Reset"     => (now + retry_after).to_s
  }

  body = {
    error: "Demasiadas solicitudes. Por favor espera antes de intentar de nuevo.",
    code:  "rate_limited",
    retry_after: retry_after
  }.to_json

  [ 429, headers, [ body ] ]
end

# ── Blocklist responder (mismo formato) ───────────────────────────────────────

Rack::Attack.blocklisted_responder = lambda do |req|
  headers = { "Content-Type" => "application/json" }
  body    = {
    error: "Acceso temporalmente bloqueado por actividad sospechosa.",
    code:  "ip_blocked"
  }.to_json

  [ 403, headers, [ body ] ]
end

# ── Logging (solo en production) ─────────────────────────────────────────────

if Rails.env.production?
  ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |_name, _start, _finish, _id, payload|
    req = payload[:request]
    Rails.logger.warn "[RackAttack] THROTTLED #{req.env['rack.attack.match_type']} " \
                      "| IP: #{req.ip} | Path: #{req.path}"
  end

  ActiveSupport::Notifications.subscribe("blocklist.rack_attack") do |_name, _start, _finish, _id, payload|
    req = payload[:request]
    Rails.logger.warn "[RackAttack] BLOCKED IP: #{req.ip} | Path: #{req.path}"
  end
end
