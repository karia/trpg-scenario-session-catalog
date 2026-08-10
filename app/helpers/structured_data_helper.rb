module StructuredDataHelper
  def scenario_description(scenario)
    [
      scenario.game_systems.map(&:name).join("／").presence,
      "#{player_count_label(scenario)}向け",
      "目安#{duration_label(scenario)}",
      scenario.synopsis.to_s.truncate(80).presence
    ].compact_blank.join("。")
  end

  def scenario_json_ld(scenario)
    data = {
      "@context" => "https://schema.org",
      "@type" => "CreativeWork",
      "name" => scenario.title,
      "genre" => "TRPG シナリオ",
      "url" => scenario_url(scenario),
      "description" => scenario_description(scenario),
      "inLanguage" => "ja"
    }
    data["author"] = scenario.authors.map { |a| { "@type" => "Person", "name" => a.name } } if scenario.authors.any?
    data["timeRequired"] = "PT#{(scenario.duration_min_hours * 60).to_i}M" if scenario.duration_min_hours.present?

    # JSON をそのまま埋めると、タイトル中の "</script" で要素を抜けられる。
    json = JSON.generate(data).gsub("<", '\\u003c')
    tag.script(json.html_safe, type: "application/ld+json", nonce: content_security_policy_nonce)
  end
end
