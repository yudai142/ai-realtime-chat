# This configuration file will be evaluated by Puma. The top-level methods that
# are invoked here are part of Puma's configuration DSL. For more information
# about methods provided by the DSL, see https://puma.io/puma/Puma/DSL.html.

# Puma starts a configurable number of processes (workers) and each process
# serves each request in a thread from an internal thread pool.
#
# The ideal number of threads per worker depends both on how much time the
# application spends waiting for IO operations and on how much you wish to
# to prioritize throughput over latency.
#
# As a rule of thumb, increasing the number of threads will increase how much
# traffic a given process can handle (throughput), but due to CRuby's
# Global VM Lock (GVL) it has diminishing returns and will degrade the
# response time (latency) of the application.
#
# The default is set to 3 threads as it's deemed a decent compromise between
# throughput and latency for the average Rails application.
#
# Any libraries that use a connection pool or another resource pool should
# be configured to provide at least as many connections as the number of
# threads. This includes Active Record's `pool` parameter in `database.yml`.
min_threads = ENV.fetch("RAILS_MIN_THREADS", 3)
max_threads = ENV.fetch("RAILS_MAX_THREADS", 3)
threads min_threads, max_threads

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
port ENV.fetch("PORT", 3000)

# Allow puma to be restarted by `bin/rails restart` command.
plugin :tmp_restart

# Specify the PID file. Defaults to tmp/pids/server.pid in development.
# In other environments, only set the PID file if requested.
pidfile ENV["PIDFILE"] if ENV["PIDFILE"]

# ========================================
# Chapter 7: Production Scale Design
# ========================================

# Workers configuration for multi-process model
# Each worker runs its own thread pool
# WEB_CONCURRENCY=0 (default) uses single process in development
# Production typically: WEB_CONCURRENCY = CPU cores
web_concurrency = ENV.fetch("WEB_CONCURRENCY", 0).to_i

if web_concurrency.positive?
  workers web_concurrency
  preload_app!
  
  # On worker boot, we can add connection pool initialization
  on_worker_boot do
    # Connection pools should be per-worker to avoid resource exhaustion
    ActiveRecord::Base.establish_connection
  end
end

# WebSocket and long-running request timeout (in seconds)
# Action Cable connections may hold connections for very long periods
# Set appropriate timeout for production load balancers (typically 61-120s)
worker_timeout 60
