class PurchaseLink < ApplicationRecord
  belongs_to :scenario

  validates :label, presence: true
  validates :url, http_url: true
end
