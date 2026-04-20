class HealthController < ActionController::Base
  def show
    checks = {
      database: check_database,
      redis:    check_redis,
      sidekiq:  check_sidekiq
    }

    status = checks.values.all? { |c| c[:ok] } ? :ok : :service_unavailable

    render json: {
      status:  status == :ok ? "ok" : "degraded",
      version: Rails.version,
      env:     Rails.env,
      checks:  checks,
      time:    Time.current.iso8601
    }, status: status
  end

  def ping
    render json: {
      status: :ok,
      time: Time.current.iso8601
    }, status: :ok
  end

  private

  def check_database
    ActiveRecord::Base.connection.execute("SELECT 1")
    { ok: true }
  rescue => e
    { ok: false, error: e.message }
  end

  def check_redis
    # Reutiliza el connection pool de Sidekiq en lugar de abrir una conexión nueva.
    Sidekiq.redis { |conn| conn.call("PING") }
    { ok: true }
  rescue => e
    { ok: false, error: e.message }
  end

  def check_sidekiq
    stats = Sidekiq::Stats.new
    { ok: true, queued: stats.enqueued, failed: stats.failed }
  rescue => e
    { ok: false, error: e.message }
  end
end
