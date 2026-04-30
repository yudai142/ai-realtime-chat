OpenAI.configure do |config|
  config.access_token = Rails.application.credentials.openai[:api_key]
  
  # ========================================
  # Chapter 7: API Resilience Settings
  # ========================================
  
  # Request timeout (seconds) - streaming responses may take longer
  # Default 60 seconds, can be increased for large responses
  config.request_timeout = ENV.fetch("OPENAI_REQUEST_TIMEOUT", 60).to_i
  
  # Optional: Configure custom connection class with retry logic
  # This is handled by the OpenAI gem internally with Faraday middleware
  # For production, consider:
  # - Faraday::Retry::Middleware :: retry on 429, 500, 502, 503, 504
  # - Exponential backoff with configurable max retries
end

# Advanced: Custom Faraday middleware configuration (if needed in future)
# config.request_options = {
#   timeout: ENV.fetch("OPENAI_REQUEST_TIMEOUT", 60).to_i
# }