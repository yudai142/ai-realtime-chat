class ConversationsController < ApplicationController
  before_action :set_conversation, only: [:show, :edit, :update, :destroy, :preset, :retitle, :share, :archive, :restore]

  # Chapter 9-4: Index action with search and list/select
  def index
    @q = params[:q].to_s
    scope = current_user.conversations.active.order(updated_at: :desc)
    @conversations = @q.present? ? scope.where("title ILIKE ?", "%#{@q}%") : scope
    @conversation = params[:id].present? ? current_user.conversations.find_by(id: params[:id]) : @conversations.first
    @conversation ||= current_user.conversations.create!(title: "New conversation")
    render :show
  end

  def show
    @q = params[:q].to_s
    @conversations = current_user.conversations.active.order(updated_at: :desc)
  end

  # Chapter 9-4: Create action
  def create
    convo = current_user.conversations.create!(title: "New conversation")
    redirect_to conversation_path(convo)
  end

  def edit; end

  def update
    if params[:preset].present?
      p = PROMPT_PRESETS[params[:preset]]
      @conversation.system_prompt = p[:system] if p
    end
    if @conversation.update(conversation_params)
      redirect_to conversation_path(@conversation), notice: "設定を更新しました"
    else
      flash.now[:alert] = @conversation.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @conversation.destroy!
    redirect_to conversations_path
  end

  # Chapter 9-4: Preset action (moved from show)
  def preset
    if params[:preset].present?
      preset = PROMPT_PRESETS[params[:preset]]
      @preset_system_prompt = preset[:system] if preset
    end

    respond_to do |format|
      format.turbo_stream # プリセット選択時
    end
  end

  # Chapter 9-4: Retitle action (auto-generate title)
  def retitle
    title = Ai::TitleGenerator.new(@conversation).call
    @conversation.update!(title: title)
    redirect_to conversation_path(@conversation), notice: "タイトルを更新しました"
  end

  # Chapter 10: Share action (signed_id 発行)
  def share
    token = @conversation.signed_id(purpose: :share, expires_in: 7.days)
    url = shared_conversation_url(token: token)
    render json: { url: url, expires_at: 7.days.from_now.iso8601 }
  end

  # Chapter 10: Archive action
  def archive
    @conversation.update!(archived_at: Time.current)
    redirect_to conversations_path, notice: "アーカイブしました"
  end

  # Chapter 10: Restore action (復元)
  def restore
    @conversation.update!(archived_at: nil)
    redirect_to conversation_path(@conversation), notice: "復元しました"
  end

  private
  def set_conversation
    @conversation = current_user.conversations.find(params[:id])
  end

  def conversation_params
    params.require(:conversation).permit(:system_prompt, :model, :temperature, :top_p, :presence_penalty, :frequency_penalty)
  end
end