class SiteSetting < ApplicationRecord
  validates :google_analytics_measurement_id,
    allow_blank: true,
    format: {
      with: /\AG-[A-Z0-9]+\z/,
      message: "は G- から始まる測定 ID を入力してください"
    }

  def self.current
    find_or_initialize_by(id: 1)
  end
end
