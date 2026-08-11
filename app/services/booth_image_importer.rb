class BoothImageImporter
  Result = Data.define(:success, :message) do
    def success? = success
  end

  def initialize(scenario, client: BoothHttpClient.new)
    @scenario = scenario
    @client = client
  end

  def call(force:)
    source_url = scenario.booth_purchase_url
    return without_source(force:) if source_url.blank?
    return Result.new(success: true, message: "BOOTH画像は最新です") if current_source?(source_url) && !force

    page = client.get(source_url, kind: :page)
    image_url = extract_image_url(page.body, source_url)
    image = client.get(image_url, kind: :image)
    validate_image!(image, image_url)
    attach(image, image_url, source_url)

    Result.new(success: true, message: "BOOTH画像を更新しました")
  rescue BoothHttpClient::Error, Nokogiri::XML::SyntaxError, StandardError => error
    Rails.logger.warn("BOOTH image import failed for scenario #{scenario.id}: #{error.message}")
    Result.new(success: false, message: "BOOTH画像を取得できませんでした")
  end

  private
    attr_reader :scenario, :client

    def without_source(force:)
      if force
        Result.new(success: false, message: "BOOTHの入手先URLがありません")
      else
        scenario.booth_image.purge if scenario.booth_image.attached?
        Result.new(success: true, message: "BOOTH画像を削除しました")
      end
    end

    def current_source?(source_url)
      scenario.booth_image.attached? && scenario.booth_image.blob.metadata["source_url"] == source_url
    end

    def extract_image_url(html, source_url)
      content = Nokogiri::HTML.parse(html).at_css('meta[property="og:image"]')&.[]("content")
      raise BoothHttpClient::Error, "og:image is missing" if content.blank?

      URI.join(source_url, content).to_s
    end

    def attach(image, image_url, source_url)
      filename = File.basename(URI.parse(image_url).path).presence || "booth-image"
      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new(image.body), filename:, content_type: image.content_type,
        metadata: { source_url: }
      )
      scenario.booth_image.attach(blob)
    rescue StandardError
      blob&.purge
      raise
    end

    def validate_image!(image, image_url)
      detected = Marcel::MimeType.for(StringIO.new(image.body))
      raise BoothHttpClient::Error, "invalid image" unless detected.in?(%w[image/png image/jpeg image/gif image/webp])
    end
end
