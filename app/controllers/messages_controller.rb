class MessagesController < ApplicationController
  before_action :set_conversation
  def index; end

  def create
    content = params.require(:message)[:content]

    # 1) ユーザー発言を保存
    user_msg = @conversation.messages.create!(role: :user, content: content)

    # 2) コンテキストを構築して問い合わせ
    messages = Ai::ContextBuilder.new(@conversation, limit: 20).build_with(content)
    stream_key = "chat_#{@conversation.id}"

    result = Ai::StreamingChat.new(conversation_id: @conversation.id, stream_key: stream_key).call!(messages)

    # 3) アシスタント発言を保存
    @conversation.messages.create!(
      role: :assistant,
      content: result.text,
      meta: { finish_reason: result.finish_reason }
    )

    head :ok
  end

  def stop
    Ai::StreamingChat.new(conversation_id: @conversation.id).request_stop!
    head :ok
  end

  private
  def set_conversation
    # 今回は単一会話を想定。複数会話は別章で。
    @conversation = Conversation.first_or_create!(title: "Default Conversation")
  end
end