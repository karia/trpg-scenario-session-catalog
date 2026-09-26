require "net/http"

class GoogleTokenRevoker
  ENDPOINT = URI("https://oauth2.googleapis.com/revoke")
  Error = Class.new(StandardError)

  def self.revoke(token)
    request = Net::HTTP::Post.new(ENDPOINT)
    request.set_form_data(token:)
    http = Net::HTTP.new(ENDPOINT.host, ENDPOINT.port)
    http.use_ssl = true
    http.open_timeout = 5
    http.read_timeout = 5
    response = http.request(request)
    raise Error, "Google token revoke failed: #{response.code}" unless response.is_a?(Net::HTTPSuccess)
  rescue Timeout::Error, SocketError, SystemCallError, IOError, OpenSSL::SSL::SSLError => error
    raise Error, "Google token revoke failed", cause: error
  end
end
