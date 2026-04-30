class HealthController < ApplicationController
  skip_before_action :require_login, only: [:status]
  skip_before_action :verify_authenticity_token, only: [:status]

  # GET /healthz
  # Health check endpoint for monitoring systems
  # Returns JSON with:
  # - ok: Overall health status (boolean)
  # - db: Database connectivity (boolean)
  # - redis: Redis connectivity (boolean)
  # - timestamp: Response timestamp (ISO 8601)
  def status
    health = check_health
    
    status_code = health[:ok] ? 200 : 503
    render json: health, status: status_code
  end

  private

  def check_health
    db_ok = check_database
    redis_ok = check_redis
    
    {
      ok: db_ok && redis_ok,
      db: db_ok,
      redis: redis_ok,
      timestamp: Time.current.iso8601
    }
  end

  def check_database
    # Quick connectivity check
    ActiveRecord::Base.connection.execute("SELECT 1")
    true
  rescue => e
    Rails.logger.error("Health check - DB error: #{e.message}")
    false
  end

  def check_redis
    # Quick Redis ping
    redis = Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/1"))
    redis.ping == "PONG"
  rescue => e
    Rails.logger.error("Health check - Redis error: #{e.message}")
    false
  ensure
    redis&.close
  end
end
