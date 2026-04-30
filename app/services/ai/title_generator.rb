# Chapter 9-6: Auto-generate conversation titles
class Ai::TitleGenerator
  LIMIT = 20

  def initialize(conversation, sample: 6)
    @conversation = conversation
    @sample = sample
  end

  def call(model: "gpt-4o-mini")
    client = OpenAI::Client.new
    recent = @conversation.messages.order(created_at: :desc).limit(@sample).reverse
    body = recent.map { |m| "[#{m.role}] #{m.content}" }.join("\n")

    sys = <<~SYS
      あなたは会話の要約タイトルを1行で作るアシスタントです。
      条件: 日本語 / 20字以内 / 絵文字・記号・括弧なし / 具体性重視 / 名詞句で簡潔に。
      出力はタイトルのみ（前後の説明や引用符を含めない）。
    SYS

    resp = client.chat(parameters: {
      model: model,
      temperature: 0.3,
      messages: [
        { role: "system", content: sys },
        { role: "user", content: body }
      ]
    })

    title = resp.dig("choices", 0, "message", "content").to_s.strip
    normalize(title)
  end

  private
  def normalize(s)
    s = s.gsub(/[\p{Cf}\p{C}]/, "").gsub(/[\r\n]+/, " ").strip
    s = s.gsub(/["'「」\[\]()（）【】]/, "")
    s.size > LIMIT ? s[0, LIMIT] : s
  end
end
