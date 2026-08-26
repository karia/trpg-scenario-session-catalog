require "net/http"
require "json"

class DiscordGuildMemberClient
  Error = Class.new(StandardError)
  GuildMembersPermissionError = Class.new(Error)
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
    cached_result(key) do
      ensure_not_rate_limited!
      response = request("/api/v10/guilds/#{guild_id}/members/#{user_id}")
      if response.is_a?(Net::HTTPSuccess)
        true
      elsif response.is_a?(Net::HTTPNotFound)
        false
      else
        handle_error_response(response)
      end
    end
  end

  def guild_members(guild_id)
    raise ArgumentError, "invalid Discord ID" unless guild_id.to_s.match?(/\A\d{17,20}\z/)

    cached_result("discord:guild-members:#{guild_id}") do
      fetch_guild_members(guild_id)
    end
  end

  private
    def cached_result(key)
      cached = @cache.read(key)
      return cached unless cached.nil?

      result = yield
      @cache.write(key, result, expires_in: RESULT_TTL)
      @cache.write("#{key}:recent", result, expires_in: RECENT_RESULT_TTL)
      result
    rescue Error
      recent = @cache.read("#{key}:recent")
      raise if recent.nil?

      @cache.write(key, recent, expires_in: RESULT_TTL)
      recent
    end

    def fetch_guild_members(guild_id)
      members = []
      after = nil
      loop do
        ensure_not_rate_limited!
        path = "/api/v10/guilds/#{guild_id}/members?limit=1000"
        path += "&after=#{after}" if after
        response = request(path)
        handle_error_response(response) unless response.is_a?(Net::HTTPSuccess)
        page = parse_guild_members(response.body)
        members.concat(page)
        break if page.size < 1_000

        after = page.last.fetch("id")
      end
      members
    end

    def parse_guild_members(body)
      JSON.parse(body).map do |member|
        user = member.fetch("user")
        {
          "id" => user.fetch("id"),
          "username" => user.fetch("username"),
          "display_name" => member["nick"].presence || user["global_name"].presence || user.fetch("username"),
          "avatar" => user["avatar"]
        }
      end
    rescue JSON::ParserError, KeyError, TypeError => error
      raise Error, "Discord API returned invalid guild members: #{error.message}"
    end

    def ensure_not_rate_limited!
      raise Error, "Discord API is rate limited" if @cache.exist?(RATE_LIMIT_KEY)
    end

    def handle_error_response(response)
      raise GuildMembersPermissionError, "Discord guild members permission is missing" if response.is_a?(Net::HTTPForbidden)

      remember_rate_limit(response) if response.is_a?(Net::HTTPTooManyRequests)
      raise Error, "Discord API returned #{response.code}"
    end

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
