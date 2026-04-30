class ConversationsController < ApplicationController
  before_action :set_conversation

  def edit; end

  def update
    if params[:preset].present?
      p = PROMPT_PRESETS[params[:preset]]
      @conversation.system_prompt = p[:system] if p
    end
    if @conversation.update(conversation_params)
      redirect_to root_path, notice: "設定を更新しました"
    else
      flash.now[:alert] = @conversation.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    end
  end

  def show
    if params[:preset].present?
      preset = PROMPT_PRESETS[params[:preset]]
      @preset_system_prompt = preset[:system] if preset
    end

    respond_to do |format|
      format.turbo_stream # プリセット選択時
    end
  end

  private
  def set_conversation
    @conversation = Conversation.first_or_create!(title: "Default Conversation")
  end

  def conversation_params
    params.require(:conversation).permit(:system_prompt, :model, :temperature, :top_p, :presence_penalty, :frequency_penalty)
  end
end