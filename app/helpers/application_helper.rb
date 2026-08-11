module ApplicationHelper
  YOUTUBE_VIDEO_ID = /\A[\w-]{11}\z/

  def youtube_embed_url(url)
    uri = URI.parse(url)
    video_id = youtube_video_id(uri)

    "https://www.youtube-nocookie.com/embed/#{video_id}" if video_id&.match?(YOUTUBE_VIDEO_ID)
  rescue URI::InvalidURIError, Rack::QueryParser::InvalidParameterError
    nil
  end

  private
    def youtube_video_id(uri)
      host = uri.host&.downcase

      return uri.path.delete_prefix("/").split("/").first if host == "youtu.be"
      return unless %w[youtube.com www.youtube.com m.youtube.com].include?(host)

      segments = uri.path.split("/").reject(&:blank?)
      return Rack::Utils.parse_query(uri.query)["v"] if segments.first == "watch"
      segments.second if %w[embed shorts live].include?(segments.first)
    end
end
