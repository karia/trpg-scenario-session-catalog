class PlaySession < ApplicationRecord
  enum :status, { scheduled: 0, played: 1, cancelled: 2 }, validate: true

  belongs_to :scenario
  has_many :participations, -> { order(:position, :id) }, dependent: :destroy, inverse_of: :play_session
  has_many :people, through: :participations

  accepts_nested_attributes_for :participations, allow_destroy: true, reject_if: :all_blank

  validates :recording_url, http_url: true

  # 日付が無い回を末尾に固定する。データベース既定の NULL の並びに任せない。
  scope :newest_first, -> { order(Arel.sql("played_on DESC NULLS LAST"), started_at: :desc, id: :desc) }

  def gm = participations.find { |p| p.gm? }&.person
end
