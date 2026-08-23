module ApplicationHelper
  YOUTUBE_VIDEO_ID = /\A[\w-]{11}\z/
  # 非 ASCII を許すと URL 直後の地の文を取り込むため ASCII 限定。代償として非 ASCII を含む URL は途中で切れる。
  HTTP_URL = URI::DEFAULT_PARSER.make_regexp(%w[http https])

  def accessible_error_summary(record)
    return unless record.errors.any?

    content_tag(:div, class: "border border-seal bg-surface p-4 text-sm text-seal", role: "alert",
      tabindex: "-1", data: { controller: "error-summary" }) do
      safe_join([
        content_tag(:h2, "入力内容を確認してください", class: "font-bold"),
        content_tag(:ul, class: "mt-2 list-disc pl-5") do
          safe_join(record.errors.map do |error|
            message = error.full_message
            next content_tag(:li, message) if error.attribute == :base

            content_tag(:li, link_to(message, "#", class: "underline", data: { error_attribute: error.attribute }))
          end)
        end
      ])
    end
  end

  def auto_link_urls(text)
    cursor = 0
    fragments = text.to_s.to_enum(:scan, HTTP_URL).map do
      match = Regexp.last_match
      url, suffix = split_url_suffix(match[0])
      preceding_text = ERB::Util.html_escape(text[cursor...match.begin(0)])
      cursor = match.end(0)
      safe_join([ preceding_text, link_to(url, url, target: "_blank", rel: "noopener"), suffix ])
    end

    safe_join([ *fragments, ERB::Util.html_escape(text.to_s[cursor..]) ])
  end

  def youtube_embed_url(url)
    uri = URI.parse(url)
    video_id = youtube_video_id(uri)

    "https://www.youtube.com/embed/#{video_id}" if video_id&.match?(YOUTUBE_VIDEO_ID)
  rescue URI::InvalidURIError, Rack::QueryParser::InvalidParameterError
    nil
  end

  private
    def split_url_suffix(url)
      suffix = url.slice!(/[,.!?;:、。]+\z/) || ""
      while url.end_with?(")") && url.count("(") < url.count(")")
        suffix.prepend(url.slice!(-1))
      end
      [ url, suffix ]
    end

    def youtube_video_id(uri)
      host = uri.host&.downcase

      return uri.path.delete_prefix("/").split("/").first if host == "youtu.be"
      return unless %w[youtube.com www.youtube.com m.youtube.com].include?(host)

      segments = uri.path.split("/").reject(&:blank?)
      return Rack::Utils.parse_query(uri.query)["v"] if segments.first == "watch"
      segments.second if %w[embed shorts live].include?(segments.first)
    end
end
