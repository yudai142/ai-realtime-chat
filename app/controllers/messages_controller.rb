class MessagesController < ApplicationController
  before_action :set_conversation

  def create
    content = params.require(:message)[:content]

    # アプリ内レート制限
    limiter = RateLimiter.new(namespace: "messages", limit: 20, period: 60)
    key = current_user.id
    unless limiter.allowed?(key)
      stream_key = "chat_u#{current_user.id}_c#{@conversation.id}"
      ActionCable.server.broadcast(stream_key, { event: "error", body: "Rate limit exceeded. Please wait." })
      head :too_many_requests and return
    end

    # 保存（第4章と同様）
    @conversation.messages.create!(role: :user, content: content)

    # コンテキストと会話設定
    messages = Ai::ContextBuilder.new(@conversation, limit: 20).build_with(content)
    stream_key = "chat_u#{current_user.id}_c#{@conversation.id}"
    opts = @conversation.params_for_openai

    Rails.logger.info("Messages to OpenAI: #{messages.inspect}")
    Rails.logger.info("OpenAI params: #{opts.inspect}")

    result = Ai::StreamingChat.new(conversation_id: @conversation.id, stream_key: stream_key)
                              .call!(messages, **opts)

    @conversation.messages.create!(role: :assistant, content: result.text, meta: { finish_reason: result.finish_reason })
    head :ok
  end

  private
  def set_conversation
    @conversation = current_user.conversations.first_or_create!(title: "Default Conversation")
  end
end