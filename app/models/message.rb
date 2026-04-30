class Message < ApplicationRecord
  enum role: { user: 0, assistant: 1, system: 2 }

  belongs_to :conversation
  validates :content, presence: true

  scope :for_openai, -> {
    order(:created_at).map { |m|
      { role: m.role_for_api, content: m.content }
    }
  }

  # OpenAI API 用に role を文字列キーで返す
  def role_for_api
    self.class.roles.key(self.role)
  end
end