class SessionSchedule < ApplicationRecord
  belongs_to :play_session
  has_many :recording_links, -> { order(:position, :id) }, dependent: :destroy, inverse_of: :session_schedule

  accepts_nested_attributes_for :recording_links, allow_destroy: true,
    reject_if: ->(attrs) { attrs["url"].blank? }
end
