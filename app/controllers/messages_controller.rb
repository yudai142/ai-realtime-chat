class MessagesController < ApplicationController
  before_action :set_conversation

  def create
    content = params.require(:message)[:content]

    # 保存（第4章と同様）
    @conversation.messages.create!(role: :user, content: content)

    # コンテキストと会話設定
    messages = Ai::ContextBuilder.new(@conversation, limit: 20).build_with(content)
    stream_key = "chat_#{@conversation.id}"
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
    @conversation = Conversation.first_or_create!(title: "Default Conversation")
  end
end