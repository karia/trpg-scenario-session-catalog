class RecordingLink < ApplicationRecord
  belongs_to :session_schedule

  validates :url, presence: true, http_url: true
end
