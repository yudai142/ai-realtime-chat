class Ai::MarkdownExporter
  def initialize(conversation)
    @conversation = conversation
  end

  def call
    lines = []
    lines << "# #{title}"
    lines << ""
    lines << "- Exported: #{Time.current.iso8601}"
    lines << "- Messages: #{@conversation.messages.count}"
    lines << ""
    @conversation.messages.order(:created_at).each do |m|
      role = m.role || "user"
      ts = m.created_at.strftime("%Y-%m-%d %H:%M")
      lines << "## [#{role}] #{ts}"
      lines << ""
      lines << indent(code_safe(m.content))
      lines << ""
    end
    lines.join("\n")
  end

  private

  def title
    @conversation.title.presence || "Conversation ##{@conversation.id}"
  end

  # コードブロックの崩れを抑える最低限のケア
  def code_safe(text)
    s = text.to_s
    fence = "```"
    s += "\n#{fence}" if s.scan(fence).length.odd?
    s
  end

  def indent(s)
    s.split("\n").map { |l| l.empty? ? "" : l }.join("\n")
  end
end
