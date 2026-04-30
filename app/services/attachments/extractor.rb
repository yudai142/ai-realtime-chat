module Attachments
  class Extractor
    MAX_PAGES = Integer(ENV.fetch("PDF_SUMMARY_PAGES", 6))
    MAX_CHARS = Integer(ENV.fetch("ATTACH_TEXT_LIMIT", 8000))

    def initialize(view_context)
      @view = view_context # url_for等に利用
    end

    # return: Array of { kind: :image|:pdf|:text, url: ..., text: ..., filename: ... }
    def call(attachments)
      Array(attachments).map { |att| extract_one(att) }.compact
    end

    private

    def extract_one(att)
      ct = att.content_type.to_s
      if ct.start_with?("image/")
        # ローカルファイルをBase64エンコードしてdata URIに変換
        mime_type =
          case File.extname(att.filename.to_s).downcase
          when ".jpg", ".jpeg" then "image/jpeg"
          when ".png"          then "image/png"
          when ".gif"          then "image/gif"
          else "application/octet-stream"
          end
        blob = att.download
        base64 = Base64.strict_encode64(blob)
        data_uri = "data:#{mime_type};base64,#{base64}"
        { kind: :image, filename: att.filename.to_s, data_uri: data_uri }
      elsif ct == "application/pdf"
        { kind: :pdf, text: extract_pdf(att), filename: att.filename.to_s }
      elsif ct.start_with?("text/")
        { kind: :text, text: extract_text(att), filename: att.filename.to_s }
      else
        # 未対応はスキップ（後で拡張）
        nil
      end
    end

    def extract_pdf(att)
      io = StringIO.new(att.download)
      reader = PDF::Reader.new(io)
      buf = +""
      reader.pages.first(MAX_PAGES).each do |page|
        buf << page.text.to_s.gsub("\u0000", "") << "\n\n"
        break if buf.length >= MAX_CHARS
      end
      truncate(buf)
    rescue => e
      Rails.logger.warn(pdf_extract_error: e.message, blob_id: att.blob_id)
      "(PDFのテキスト抽出に失敗しました)"
    end

    def extract_text(att)
      truncate(att.download.force_encoding("UTF-8"))
    rescue => e
      Rails.logger.warn(text_extract_error: e.message, blob_id: att.blob_id)
      "(テキスト抽出に失敗しました)"
    end

    def truncate(s)
      s = s.to_s
      return s if s.length <= MAX_CHARS
      s[0...MAX_CHARS] + "\n...[truncated]"
    end
  end
end
