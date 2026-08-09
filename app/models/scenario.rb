class Scenario < ApplicationRecord
  # 「-」と空欄は列挙値ではなく NULL として扱う。
  enum :character_sheet_deadline, {
    day_before: 0,
    two_days_before: 1,
    one_week_before: 2,
    not_required: 3,
    see_note: 4
  }, validate: { allow_nil: true }

  has_one_attached :jacket

  has_many :scenario_game_systems, dependent: :destroy
  has_many :game_systems, through: :scenario_game_systems
  has_many :scenario_authors, dependent: :destroy
  has_many :authors, through: :scenario_authors
  has_many :purchase_links, -> { order(:position, :id) }, dependent: :destroy, inverse_of: :scenario
  has_many :stream_links, -> { order(:position, :id) }, dependent: :destroy, inverse_of: :scenario

  validates :title, presence: true
  validates :recommendation, inclusion: { in: 1..5 }, allow_nil: true
  validate :player_count_range_is_ordered
  validate :duration_range_is_ordered

  private
    def player_count_range_is_ordered
      return if player_count_min.blank? || player_count_max.blank?
      return if player_count_min <= player_count_max

      errors.add(:player_count_max, :greater_than_or_equal_to, count: player_count_min)
    end

    def duration_range_is_ordered
      return if duration_min_minutes.blank? || duration_max_minutes.blank?
      return if duration_min_minutes <= duration_max_minutes

      errors.add(:duration_max_minutes, :greater_than_or_equal_to, count: duration_min_minutes)
    end
end
