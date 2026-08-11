class PlaySession < ApplicationRecord
  belongs_to :scenario
  has_many :session_schedules, -> { order(Arel.sql("started_at ASC NULLS LAST"), :position, :id) },
    dependent: :destroy, inverse_of: :play_session
  has_many :participations, -> { order(:position, :id) }, dependent: :destroy, inverse_of: :play_session
  has_many :people, through: :participations

  # person_id が空の行は増やしただけの行なので捨てる。role には既定値があり all_blank では消えない。
  accepts_nested_attributes_for :session_schedules, allow_destroy: true,
    reject_if: lambda { |attrs|
      recordings = attrs["recording_links_attributes"]
      recordings = recordings.values if recordings.respond_to?(:values)
      attrs["started_at"].blank? && Array(recordings).all? { |recording| recording["url"].blank? }
    }
  accepts_nested_attributes_for :participations, allow_destroy: true,
    reject_if: ->(attrs) { attrs["person_id"].blank? }

  validates :cocofolia_url, http_url: true
  validate :participants_are_distinct

  # 日付が無い回を末尾に固定する。データベース既定の NULL の並びに任せない。
  scope :newest_first, -> {
    left_joins(:session_schedules).group(:id)
      .order(Arel.sql("MIN(session_schedules.started_at) DESC NULLS LAST"), id: :desc)
  }

  def derived_status(now = Time.current)
    starts = session_schedules.filter_map(&:started_at)
    return :scheduled if starts.empty? || now < starts.first
    return :in_progress if now < starts.last

    :completed
  end

  private
    # 一意制約は DB にもあるが、同じ送信内に重複があると例外になる前に弾く必要がある。
    def participants_are_distinct
      ids = participations.reject(&:marked_for_destruction?).filter_map(&:person_id)
      return if ids.uniq.size == ids.size

      errors.add(:base, "同じ人を複数の行に指定できません")
    end
end
