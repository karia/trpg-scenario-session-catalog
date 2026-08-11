module ScenariosHelper
  UNSET = "未設定".freeze

  def list_view_class(name, current)
    name == current ? "font-bold text-ink no-underline" : "text-seal"
  end

  def scenario_order_options(listing)
    choices = ScenarioListing::ORDERS.keys.map { |key| [ t("scenarios.orders.#{key}"), key ] }

    options_for_select([ [ t("scenarios.orders.gm"), "" ] ] + choices, listing.order.to_s)
  end

  # 値が無ければ nil。一覧は空欄に、詳細は「未設定」に落とす。
  def player_count_value(scenario)
    bounded_label(scenario.player_count_min, scenario.player_count_max) { |n| "#{n}人" }
  end

  def player_count_label(scenario) = player_count_value(scenario) || UNSET

  def duration_value(scenario)
    bounded_label(scenario.duration_min_hours, scenario.duration_max_hours) { |n| humanized_hours(n) }
  end

  def duration_label(scenario) = duration_value(scenario) || UNSET

  def character_sheet_deadline_label(scenario)
    return scenario.character_sheet_deadline_note if scenario.character_sheet_deadline_note.present?
    return UNSET if scenario.character_sheet_deadline.blank?

    t("scenarios.character_sheet_deadlines.#{scenario.character_sheet_deadline}")
  end

  def humanized_hours(hours)
    formatted = (hours % 1).zero? ? hours.to_i : hours.to_f
    "#{formatted}時間"
  end

  private
    # 片側だけ埋まっている場合に、確定値と取り違えられない形にする。
    def bounded_label(min, max)
      return nil if min.blank? && max.blank?
      return "#{yield(min)}以上" if max.blank?
      return "#{yield(max)}まで" if min.blank?
      return yield(min) if min == max

      "#{yield(min)}〜#{yield(max)}"
    end
end
