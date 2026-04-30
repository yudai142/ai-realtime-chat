class Ai::StreamingChat
  def call!(messages, model: "gpt-4o-mini", **opts)
    client = OpenAI::Client.new
    buffer = +""
    finish_reason = nil

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
            broadcast(event: "delta", body: delta)
          end
          fr = chunk.dig("choices", 0, "finish_reason")
          finish_reason = fr if fr
        end
      }.compact
    )

    broadcast(event: "done", body: "", meta: { finish_reason: finish_reason })
    Result.new(text: buffer, finish_reason: finish_reason)
  rescue => e
    broadcast(event: "error", body: e.message)
    raise
  ensure
    clear_stop!
  end
end