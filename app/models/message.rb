class Message < ApplicationRecord
  enum role: { user: 0, assistant: 1, system: 2 }

  belongs_to :conversation
  validates :content, presence: true

  scope :for_openai, -> {
    order(:created_at).pluck(:role, :content).map { |r, c|
      { role: r, content: c }
    }
  }
end