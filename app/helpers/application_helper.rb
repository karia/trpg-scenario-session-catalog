module ApplicationHelper
  YOUTUBE_VIDEO_ID = /\A[\w-]{11}\z/
  HTTP_URL = URI::DEFAULT_PARSER.make_regexp(%w[http https])

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
