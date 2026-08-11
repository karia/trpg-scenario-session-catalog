class Scenario < ApplicationRecord
  # 「-」と空欄は列挙値ではなく NULL として扱う。
  enum :character_sheet_deadline, {
    day_before: 0,
    two_days_before: 1,
    one_week_before: 2,
    not_required: 3,
    see_note: 4
  }, validate: { allow_nil: true }

  has_one_attached :jacket do |attachable|
    attachable.variant :thumb, resize_to_fill: [ 480, 640 ], format: :webp, saver: { quality: 80 }
    attachable.variant :cover, resize_to_limit: [ 800, 1200 ], format: :webp, saver: { quality: 85 }
  end

  has_many :scenario_game_systems, dependent: :destroy
  has_many :game_systems, through: :scenario_game_systems
  has_many :scenario_authors, dependent: :destroy
  has_many :authors, through: :scenario_authors
  has_many :favorites, dependent: :destroy
  has_many :spoiler_reveals, dependent: :destroy
  # セッションが残っているシナリオは消させない。消すと参加記録ごと失われる。
  has_many :play_sessions, dependent: :restrict_with_error
  has_many :purchase_links, -> { order(:position, :id) }, dependent: :destroy, inverse_of: :scenario
  has_many :stream_links, -> { order(:position, :id) }, dependent: :destroy, inverse_of: :scenario

  accepts_nested_attributes_for :purchase_links, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :stream_links, allow_destroy: true, reject_if: :all_blank

  # 並べ替えの途中は position が重複しうるため、一意制約を置かず id で決着させる。
  # 入れ替え中の旧 Pod が書いた行は position を持たない。PostgreSQL の昇順は NULL を最後に置くため末尾に並ぶ。
  scope :gm_ordered, -> { order(:position, :id) }

  before_create :append_to_gm_order

  # 与えられた並びに合わせて振り直す。渡されなかった行の position は動かさない。
  def self.rearrange(ids)
    transaction do
      ids.each_with_index { |id, index| where(id:).update_all(position: index + 1) }
    end
  end

  validates :title, presence: true
  validates :jacket, content_type: [ :png, :jpeg, :gif, :webp ], size: { less_than: 10.megabytes }
  # TODO: 並び順は position に移った（issue #41）。切り戻す必要がなくなったら列ごと落とす。
  validates :recommendation, inclusion: { in: 1..5 }, allow_nil: true
  # 人数での絞り込みが下限を軸にするため、下限だけは必ず要る（issue #28）。
  validates :player_count_min, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :player_count_max, numericality: { only_integer: true, greater_than_or_equal_to: 1 }, allow_nil: true
  validates :duration_min_hours, :duration_max_hours,
    numericality: { greater_than: 0 }, allow_nil: true
  validate :player_count_range_is_ordered
  validate :duration_range_is_ordered
  validate :durations_are_half_hours

  private
    def append_to_gm_order
      self.position ||= (self.class.maximum(:position) || 0) + 1
    end

    def player_count_range_is_ordered
      return if player_count_min.blank? || player_count_max.blank?
      return if player_count_min <= player_count_max

      errors.add(:player_count_max, :greater_than_or_equal_to, count: player_count_min)
    end

    def duration_range_is_ordered
      return if duration_min_hours.blank? || duration_max_hours.blank?
      return if duration_min_hours <= duration_max_hours

      errors.add(:duration_max_hours, :greater_than_or_equal_to, count: duration_min_hours)
    end

    def durations_are_half_hours
      %i[duration_min_hours duration_max_hours].each do |attribute|
        hours = public_send(attribute)
        next if hours.blank? || (hours * 2) % 1 == 0

        errors.add(attribute, "は0.5時間単位で入力してください")
      end
    end
end
