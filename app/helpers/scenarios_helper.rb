module ScenariosHelper
  def player_count_label(scenario)
    range = [ scenario.player_count_min, scenario.player_count_max ].compact
    numeric =
      case range
      when [] then nil
      else range.uniq.join("〜") + "人"
      end

    [ numeric, scenario.player_count_note ].compact_blank.join(" ").presence || "制限なし"
  end

  def duration_label(scenario)
    range = [ scenario.duration_min_minutes, scenario.duration_max_minutes ].compact
    return "未設定" if range.empty?

    range.uniq.map { |minutes| humanized_minutes(minutes) }.join("〜")
  end

  # 「30分〜60分」と「6〜7時間」の両方が読みやすい形にする。
  def humanized_minutes(minutes)
    return "#{minutes}分" if minutes < 60

    hours = minutes / 60.0
    formatted = hours == hours.to_i ? hours.to_i : hours.round(1)
    "#{formatted}時間"
  end

  def recommendation_label(scenario)
    return "回したことない" unless scenario.gm_experienced
    return "未評価" if scenario.recommendation.blank?

    "★" * scenario.recommendation
  end

  def character_sheet_deadline_label(scenario)
    return "未設定" if scenario.character_sheet_deadline.blank?

    t("scenarios.character_sheet_deadlines.#{scenario.character_sheet_deadline}")
  end
end
