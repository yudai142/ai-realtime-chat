module Ai
  class AttachmentSummarizer
    def initialize(conversation:, stream_key:)
      @conversation = conversation
      @stream_key = stream_key
    end

    # attachments_info: [{kind:, url?, text?, filename:}]
    def call!(attachments_info, model: nil)
      model ||= @conversation.model.presence || "gpt-4o-mini"

      sys = <<~SYS
        あなたはドキュメント要約アシスタントです。入力のPDFテキストや画像を読み、重要な要点を日本語で簡潔にまとめます。
        出力要件:
        - 見出し→箇条書き→次のアクションの順で。
        - コード/数式/表は簡略に言語化。あいまいな点は"不明"と記す。
        - 事実に自信がない場合は推測しない。
      SYS

      user_parts = []

      attachments_info.each do |a|
        case a[:kind]
        when :image
          user_parts << { type: "text", text: "画像: #{a[:filename]} の要点を抽出してください。" }
          user_parts << { type: "image_url", image_url: { url: a[:data_uri] } }
        when :pdf, :text
          label = a[:kind] == :pdf ? "PDF" : "テキスト"
          user_parts << { type: "text", text: "#{label}: #{a[:filename]}\n---\n#{a[:text]}" }
        end
      end

      messages = [
        { role: "system", content: sys },
        { role: "user", content: user_parts }
      ]

      # 既存の StreamingChat へ委譲
      Ai::StreamingChat.new(conversation_id: @conversation.id, stream_key: @stream_key)
                        .call!(messages, **@conversation.params_for_openai)
    end
  end
end
