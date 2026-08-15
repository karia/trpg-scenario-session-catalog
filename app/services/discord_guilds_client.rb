require "json"
require "net/http"

class DiscordGuildsClient
  Error = Class.new(StandardError)
  ENDPOINT = URI("https://discord.com/api/v10/users/@me/guilds?limit=200")

  def guild_ids(access_token)
    response = request(access_token)
    raise Error, "Discord API returned #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body).map { |guild| guild.fetch("id").to_s }
  rescue JSON::ParserError, KeyError => error
    raise Error, error.message
  end

  private
    def request(access_token)
      http = Net::HTTP.new(ENDPOINT.host, ENDPOINT.port)
      http.use_ssl = true
      http.open_timeout = 5
      http.read_timeout = 10
      http.request(Net::HTTP::Get.new(ENDPOINT, "Authorization" => "Bearer #{access_token}"))
    rescue Timeout::Error, SocketError, SystemCallError, OpenSSL::SSL::SSLError => error
      raise Error, error.message
    end
end
