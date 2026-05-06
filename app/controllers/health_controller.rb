class HealthController < ActionController::Base
  def show
    checks = {
      database:    check_database,
      solid_queue: check_solid_queue
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

  def check_solid_queue
    pending   = SolidQueue::Job.where(finished_at: nil).count
    scheduled = SolidQueue::ScheduledExecution.count
    failed    = SolidQueue::FailedExecution.count
    { ok: true, pending: pending, scheduled: scheduled, failed: failed }
  rescue => e
    { ok: false, error: e.message }
  end
end
