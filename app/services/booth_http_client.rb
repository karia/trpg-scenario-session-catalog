require "net/http"

class BoothHttpClient
  Error = Class.new(StandardError)
  Response = Data.define(:body, :content_type)

  LIMITS = { page: 1.megabyte, image: 10.megabytes }.freeze
  REDIRECT_LIMIT = 3

  def get(url, kind:)
    fetch(URI.parse(url), kind:, redirects_left: REDIRECT_LIMIT)
  rescue URI::InvalidURIError => error
    raise Error, error.message
  end

  private
    def fetch(uri, kind:, redirects_left:)
      validate_uri!(uri, kind:)
      response = request(uri, limit: LIMITS.fetch(kind))

      if response.is_a?(Net::HTTPRedirection)
        raise Error, "too many redirects" if redirects_left.zero?

        return fetch(URI.join(uri, response.fetch("location")), kind:, redirects_left: redirects_left - 1)
      end

      raise Error, "HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      body = response.body.to_s
      content_type = response["content-type"].to_s.split(";", 2).first
      validate_response!(body, content_type, kind:)
      Response.new(body:, content_type:)
    end

    def request(uri, limit:)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 5
      http.read_timeout = 10
      request = Net::HTTP::Get.new(uri, "User-Agent" => "trpg-scenario-session-catalog")
      http.request(request) do |response|
        content_length = response["content-length"]&.to_i
        raise Error, "response is too large" if content_length&.>(limit)

        body = +"".b
        response.read_body do |chunk|
          raise Error, "response is too large" if body.bytesize + chunk.bytesize > limit

          body << chunk
        end
        response.body = body
      end
    rescue Timeout::Error, SocketError, SystemCallError, OpenSSL::SSL::SSLError => error
      raise Error, error.message
    end

    def validate_uri!(uri, kind:)
      host = uri.host&.downcase
      allowed = if kind == :page
        host == "booth.pm" || host&.end_with?(".booth.pm")
      else
        host == "booth.pximg.net"
      end
      raise Error, "unsupported URL" unless uri.is_a?(URI::HTTPS) && uri.port == 443 && uri.userinfo.nil? && allowed
    end

    def validate_response!(body, content_type, kind:)
      expected = kind == :page ? "text/html" : %r{\Aimage/}
      valid_type = expected.is_a?(Regexp) ? content_type.match?(expected) : content_type == expected
      raise Error, "unexpected content type" unless valid_type
    end
end
