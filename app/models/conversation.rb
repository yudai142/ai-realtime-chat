class Conversation < ApplicationRecord
  has_many :messages, -> { order(:created_at) }, dependent: :destroy

  # 直近 N 件（既定: 20）
  def last_messages(limit = 20)
    messages.order(created_at: :asc).last(limit)
  end
end