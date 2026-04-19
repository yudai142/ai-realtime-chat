class MessagesController < ApplicationController
  def index; end

  def create
    content = params.require(:message)[:content]
    conversation_id = params[:conversation_id].presence || "global"

    ActionCable.server.broadcast("chat_#{conversation_id}", {
      sender: "system",
      content: content
    })

    head :ok
  end
end