class Ai::ContextBuilder
  DEFAULT_LIMIT = 20
  SYSTEM_PROMPT = "あなたは親切で簡潔に答えるアシスタントです。"

  def initialize(conversation, limit: DEFAULT_LIMIT)
    @conversation = conversation
    @limit = limit
  end

  def build_with(latest_user_content)
    history = @conversation.last_messages(@limit)
    messages = [{ role: "system", content: SYSTEM_PROMPT }]
    messages += history.map { |m| { role: m.role, content: m.content } }
    messages << { role: "user", content: latest_user_content }
    messages
  end
end