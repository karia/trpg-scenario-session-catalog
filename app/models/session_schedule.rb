class SessionSchedule < ApplicationRecord
  belongs_to :play_session
  has_many :recording_links, -> { order(:position, :id) }, dependent: :destroy, inverse_of: :session_schedule

  accepts_nested_attributes_for :recording_links, allow_destroy: true,
    reject_if: ->(attrs) { attrs["url"].blank? }

  def effective_start
    return if scheduled_on.blank?
    return scheduled_on.in_time_zone if started_at.blank?

    Time.zone.local(scheduled_on.year, scheduled_on.month, scheduled_on.day,
      started_at.hour, started_at.min, started_at.sec)
  end
end
