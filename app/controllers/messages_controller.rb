class MessagesController < ApplicationController
  before_action :set_conversation

  def index
    @conversations = current_user.conversations.order(updated_at: :desc)
    @conversation = current_user.conversations.first_or_create!(title: "Default Conversation")
  end

  # Chapter 9-5: Create with conversation switching support
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

    # 1) 保存
    @conversation.messages.create!(role: :user, content: content)

    # 2) コンテキストと会話設定
    messages = Ai::ContextBuilder.new(@conversation, limit: 20).build_with(content)
    stream_key = "chat_u#{current_user.id}_c#{@conversation.id}"
    opts = @conversation.params_for_openai

    Rails.logger.info("Messages to OpenAI: #{messages.inspect}")
    Rails.logger.info("OpenAI params: #{opts.inspect}")

    # 3) ストリーミング（ユーザー別ストリームキー）
    result = Ai::StreamingChat.new(conversation_id: @conversation.id, stream_key: stream_key)
                              .call!(messages, **opts)

    # 4) 応答を保存
    @conversation.update!(updated_at: Time.current)
    @conversation.messages.create!(role: :assistant, content: result.text, meta: { finish_reason: result.finish_reason })

    # 5) タイトル自動生成
    if @conversation.title.blank? || @conversation.title == "New conversation"
      begin
        title = Ai::TitleGenerator.new(@conversation).call
        @conversation.update!(title: title)
      rescue => e
        Rails.logger.warn(auto_title_error: e.message)
      end
    end

    head :ok
  end

  # ========================================
  # Chapter 8-5: Regenerate (resend last user message)
  # ========================================
  def regenerate
    # Get the last user message
    last_user = @conversation.messages.where(role: :user).order(created_at: :desc).first
    return head :unprocessable_entity unless last_user

    # Rebuild message context with the same user input
    messages = Ai::ContextBuilder.new(@conversation, limit: 20).build_with(last_user.content)
    stream_key = "chat_u#{current_user.id}_c#{@conversation.id}"
    opts = @conversation.params_for_openai

    # Call OpenAI API same as create action
    result = Ai::StreamingChat.new(conversation_id: @conversation.id, stream_key: stream_key)
                              .call!(messages, **opts)

    # Save new assistant response
    @conversation.messages.create!(role: :assistant, content: result.text, meta: { finish_reason: result.finish_reason })
    head :ok
  end

  private
  # Chapter 9-5: Set conversation with conversation_id from params or first conversation
  def set_conversation
    if params[:conversation_id].present?
      @conversation = current_user.conversations.find(params[:conversation_id])
    else
      @conversation = current_user.conversations.first_or_create!(title: "Default Conversation")
    end
  end
end