# Middleware for logging HTTP request metrics
# Captures: path, method, status code, response time, request size

class MetricsLogger
  def initialize(app)
    @app = app
  end

  def call(env)
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    
    # Call the next middleware/app
    status, headers, body = @app.call(env)
    
    # Calculate response time
    end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    response_time_ms = ((end_time - start_time) * 1000).to_i
    
    # Log metrics
    log_metrics(env, status, headers, response_time_ms)
    
    [status, headers, body]
  rescue => e
    end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    response_time_ms = ((end_time - start_time) * 1000).to_i
    
    log_metrics(env, 500, {}, response_time_ms, error: e)
    raise
  end

  private

  def log_metrics(env, status, headers, response_time_ms, error: nil)
    path = env["PATH_INFO"]
    method = env["REQUEST_METHOD"]
    
    # Skip health checks and assets from metrics logging to reduce noise
    return if path.in?(["/up", "/healthz", "/service-worker", "/manifest"])
    return if path.start_with?("/assets")
    
    # Determine slow request threshold
    slow_threshold_ms = ENV.fetch("SLOW_REQUEST_THRESHOLD_MS", 1000).to_i
    is_slow = response_time_ms >= slow_threshold_ms
    
    # Format log message
    log_level = status >= 500 ? :error : (is_slow ? :warn : :info)
    
    log_msg = "HTTP #{method} #{path} status=#{status} time=#{response_time_ms}ms"
    log_msg += " ERROR: #{error.message}" if error
    
    Rails.logger.send(log_level, log_msg)
  end
end
