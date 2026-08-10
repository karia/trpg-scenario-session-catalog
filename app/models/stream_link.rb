class StreamLink < ApplicationRecord
  belongs_to :scenario

  validates :url, presence: true, http_url: true
end
