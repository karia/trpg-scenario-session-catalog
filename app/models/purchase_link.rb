class PurchaseLink < ApplicationRecord
  belongs_to :scenario

  after_commit :refresh_booth_image

  validates :label, presence: true
  validates :url, http_url: true

  def booth?
    host = URI.parse(url.to_s).host&.downcase
    host == "booth.pm" || host&.end_with?(".booth.pm")
  rescue URI::InvalidURIError
    false
  end

  private
    def refresh_booth_image
      RefreshBoothImageJob.perform_later(scenario_id)
    end
end
