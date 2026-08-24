require "net/http"
require "json"

class DiscordGuildMemberClient
  Error = Class.new(StandardError)
  API_ORIGIN = "https://discord.com"
  USER_AGENT = "DiscordBot (https://github.com/karia/trpg-scenario-session-catalog, 1.0)"
  RATE_LIMIT_KEY = "discord:guild-member:rate-limited"
  RESULT_TTL = 1.minute
  RECENT_RESULT_TTL = 10.minutes

  def initialize(bot_token: ENV.fetch("DISCORD_BOT_TOKEN"), cache: Rails.cache)
    @bot_token = bot_token
    @cache = cache
  end

  def member?(guild_id, user_id)
    raise ArgumentError, "invalid Discord ID" unless [ guild_id, user_id ].all? { |id| id.to_s.match?(/\A\d{17,20}\z/) }

    key = "discord:guild-member:#{guild_id}:#{user_id}"
    recent_key = "#{key}:recent"
    cached = @cache.read(key)
    return cached unless cached.nil?

    raise Error, "Discord API is rate limited" if @cache.exist?(RATE_LIMIT_KEY)

    response = request("/api/v10/guilds/#{guild_id}/members/#{user_id}")
    result = if response.is_a?(Net::HTTPSuccess)
      true
    elsif response.is_a?(Net::HTTPNotFound)
      false
    else
      remember_rate_limit(response) if response.is_a?(Net::HTTPTooManyRequests)
      raise Error, "Discord API returned #{response.code}"
    end
    @cache.write(key, result, expires_in: RESULT_TTL)
    @cache.write(recent_key, result, expires_in: RECENT_RESULT_TTL)
    result
  rescue Error
    recent = @cache.read(recent_key)
    raise if recent.nil?

    @cache.write(key, recent, expires_in: RESULT_TTL)
    recent
  end

  private
    def request(path)
      uri = URI.join(API_ORIGIN, path)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 1
      http.read_timeout = 2
      http.request(Net::HTTP::Get.new(uri, "Authorization" => "Bot #{@bot_token}", "User-Agent" => USER_AGENT))
    rescue Timeout::Error, SocketError, SystemCallError, OpenSSL::SSL::SSLError => error
      raise Error, error.message
    end

    def remember_rate_limit(response)
      retry_after = JSON.parse(response.body).fetch("retry_after").to_f
      @cache.write(RATE_LIMIT_KEY, true, expires_in: retry_after.seconds)
    rescue JSON::ParserError, KeyError
      retry_after = response["Retry-After"].to_f
      @cache.write(RATE_LIMIT_KEY, true, expires_in: [ retry_after, 1 ].max.seconds)
    end
end
