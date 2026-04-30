module Ai
  class StreamingChat
    # ========================================
    # Chapter 7: Delta Batching Configuration
    # ========================================
    # Accumulate deltas for X milliseconds before broadcasting
    # Reduces CPU load, Redis calls, and frontend redraws
    # Default: 40ms (25 batches/second) - good balance for user experience
    STREAM_FLUSH_MS = ENV.fetch("STREAM_FLUSH_MS", 40).to_i
    
    Result = Struct.new(:text, :finish_reason, keyword_init: true)

    def initialize(conversation_id:, stream_key:)
      @conversation_id = conversation_id.presence || "global"
      @stream_key = stream_key
      @stop_flag_key = "stop:#{@conversation_id}"
    end

    def call!(messages, model: "gpt-4o-mini", **opts)
      client = OpenAI::Client.new
      buffer = +""               # Full accumulated text
      chunk_buf = +""            # Buffered deltas waiting for flush
      finish_reason = nil
      last_flush_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      broadcast(event: "start", body: "")

      client.chat(
        parameters: {
          model: model,
          messages: messages,
          temperature: opts[:temperature],
          top_p: opts[:top_p],
          presence_penalty: opts[:presence_penalty],
          frequency_penalty: opts[:frequency_penalty],
          stream: proc do |chunk, _bytes, _index|
            break if stop_requested?
            delta = chunk.dig("choices", 0, "delta", "content")
            
            if delta.present?
              buffer << delta
              chunk_buf << delta
              
              # Check if we should flush buffered deltas
              current_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
              elapsed_ms = ((current_time - last_flush_time) * 1000).to_i
              
              if elapsed_ms >= STREAM_FLUSH_MS
                broadcast(event: "delta", body: chunk_buf)
                chunk_buf = +""
                last_flush_time = current_time
              end
            end
            
            fr = chunk.dig("choices", 0, "finish_reason")
            finish_reason = fr if fr
          end
        }.compact
      )

      # Flush any remaining buffered content
      broadcast(event: "delta", body: chunk_buf) if chunk_buf.present?
      
      broadcast(event: "done", body: "", meta: { finish_reason: finish_reason })
      Result.new(text: buffer, finish_reason: finish_reason)
    rescue => e
      error_msg = e.message
      if e.respond_to?(:response)
        error_msg = "OpenAI API Error: #{e.response.dig(:error, :message) || e.response.inspect}"
      end
      Rails.logger.error("StreamingChat Error: #{error_msg}")
      broadcast(event: "error", body: error_msg)
      raise
    ensure
      clear_stop!
    end

    def request_stop!
      redis.setex(@stop_flag_key, 600, "1")
    end

    private
    def redis
      @redis ||= Redis.new(url: ENV.fetch("REDIS_URL", "redis://redis:6379/1"))
    end

    def stop_requested?
      redis.get(@stop_flag_key) == "1"
    end

    def clear_stop!
      redis.del(@stop_flag_key)
    end

    def broadcast(payload)
      ActionCable.server.broadcast(@stream_key, payload)
    end
  end
end