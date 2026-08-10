module ScenariosHelper
  UNSET = "未設定".freeze

  def list_view_class(name, current)
    name == current ? "font-bold text-ink no-underline" : "text-seal"
  end

  # 一覧では、値が無い欄は空欄のままにする（issue #20）。
  def blank_to_empty(label) = label == UNSET ? "" : label

  def player_count_label(scenario)
    numeric = bounded_label(scenario.player_count_min, scenario.player_count_max) { |n| "#{n}人" }

    [ numeric, scenario.player_count_note ].compact_blank.join(" ").presence || UNSET
  end

  def duration_label(scenario)
    min = scenario.duration_min_minutes
    max = scenario.duration_max_minutes
    return UNSET if min.blank? && max.blank?

    # 2 時間未満は分のままのほうが元データに近く、範囲でも単位が揃う。
    unit = [ min, max ].compact.max < 120 ? :minutes : :hours
    bounded_label(min, max) { |n| humanized_minutes(n, unit:) }
  end

  def character_sheet_deadline_label(scenario)
    return scenario.character_sheet_deadline_note if scenario.character_sheet_deadline_note.present?
    return UNSET if scenario.character_sheet_deadline.blank?

    t("scenarios.character_sheet_deadlines.#{scenario.character_sheet_deadline}")
  end

  # 「30分〜1時間」のように単位が混ざると読みにくいため、範囲は単位を揃える。
  def humanized_minutes(minutes, unit: nil)
    unit ||= minutes < 60 ? :minutes : :hours
    return "#{minutes}分" if unit == :minutes

    hours = minutes / 60.0
    formatted = (hours % 1).zero? ? hours.to_i : hours.round(1)
    "#{formatted}時間"
  end

  private
    # 片側だけ埋まっている場合に、確定値と取り違えられない形にする。
    def bounded_label(min, max)
      return nil if min.blank? && max.blank?
      return yield(min) if max.blank?
      return "#{yield(max)}まで" if min.blank?
      return yield(min) if min == max

      "#{yield(min)}〜#{yield(max)}"
    end
end
