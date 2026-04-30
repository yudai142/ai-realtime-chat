# Redis configuration for Rails cache store and Action Cable
# ========================================
# Chapter 7: Redis Connection Pool Setup
# ========================================
# 
# In development: Cache store is configured in config/environments/development.rb
# In production: Configure via environment variables:
#   REDIS_URL=redis://redis-hostname:6379/1
#   REDIS_POOL_SIZE=10 (optional, handled by Rails internally)
#
# Action Cable uses Redis from REDIS_URL environment variable

redis_url = ENV.fetch("REDIS_URL", "redis://localhost:6379/1")

# Make Redis client available for services that need direct access
# (Only for custom Redis operations, Rails.cache handles pooling)
require 'redis'

