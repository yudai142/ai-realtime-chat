class MessagesController < ApplicationController
  def index; end
  
  def create
    content = params.require(:message)[:content]
    conversation_id = params[:conversation_id].presence || "global"
    stream_key = "chat_#{conversation_id}"

    # 最小のロール設計（第5章で拡張）
    messages = [
      { role: "system", content: "あなたは親切で簡潔に答えるアシスタントです。" },
      { role: "user",   content: content }
    ]

    result = Ai::StreamingChat.new(conversation_id:, stream_key:).call!(messages)

    Rails.logger.info(convo: conversation_id, finish: result.finish_reason, text_len: result.text.length)
    head :ok
  end

  # Stop ボタンから呼び出す
  def stop
    conversation_id = params[:conversation_id].presence || "global"
    Ai::StreamingChat.new(conversation_id:).request_stop!
    head :ok
  end
end