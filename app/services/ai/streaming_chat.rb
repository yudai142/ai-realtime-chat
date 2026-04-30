class Ai::StreamingChat
  Result = Struct.new(:text, :finish_reason, keyword_init: true)

  def initialize(conversation_id:, stream_key: nil)
    @conversation_id = conversation_id.presence || "global"
    @stream_key = stream_key.presence || "chat_#{@conversation_id}"
    @stop_flag_key = "stop:#{@conversation_id}"
  end

  # messages: [{role: "system"|"user"|"assistant", content: "..."}, ...]
  def call!(messages, model: "gpt-4o-mini")
    client = OpenAI::Client.new

    full_text = +""
    finish_reason = nil

    broadcast(event: "start", body: "")

    # 任意: TTFT計測（最初のdelta到着までの時間）
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    first_delta_at = nil

    client.chat(
      parameters: {
        model: model,
        messages: messages,
        stream: proc do |chunk, _bytes, _index|
          break if stop_requested?

          delta = chunk.dig("choices", 0, "delta", "content")

          if delta
            # TTFT
            if !first_delta_at
              first_delta_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
              Rails.logger.info(event: "ttft", ms: ((first_delta_at - started) * 1000).round,
                                model: model, convo: @conversation_id, stream_key: @stream_key)
            end

            full_text << delta
            broadcast(event: "delta", body: delta)
          end

          fr = chunk.dig("choices", 0, "finish_reason")
          finish_reason = fr if fr
        end
      }
    )

    broadcast(event: "done", body: "", meta: { finish_reason: finish_reason })
    Result.new(text: full_text, finish_reason: finish_reason)
  rescue => e
    broadcast(event: "error", body: e.message)
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