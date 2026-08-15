require "net/http"

class DiscordGuildMemberClient
  Error = Class.new(StandardError)
  API_ORIGIN = "https://discord.com"

  def initialize(bot_token: ENV.fetch("DISCORD_BOT_TOKEN"))
    @bot_token = bot_token
  end

  def member?(guild_id, user_id)
    raise ArgumentError, "invalid Discord ID" unless [ guild_id, user_id ].all? { |id| id.to_s.match?(/\A\d{17,20}\z/) }

    response = request("/api/v10/guilds/#{guild_id}/members/#{user_id}")
    return true if response.is_a?(Net::HTTPSuccess)
    return false if response.is_a?(Net::HTTPNotFound)

    raise Error, "Discord API returned #{response.code}"
  end

  private
    def request(path)
      uri = URI.join(API_ORIGIN, path)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 5
      http.read_timeout = 10
      http.request(Net::HTTP::Get.new(uri, "Authorization" => "Bot #{@bot_token}"))
    rescue Timeout::Error, SocketError, SystemCallError, OpenSSL::SSL::SSLError => error
      raise Error, error.message
    end
end
